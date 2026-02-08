#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/demo.xcodeproj"
SCHEME="${SCHEME:-demo}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/DerivedData-launch-mac}"
DESTINATION="${DESTINATION:-platform=macOS}"

clean_build=false
clean_only=false
deep_clean=false
clean_local_derived=true
open_app=true

usage() {
  cat <<'EOF'
Usage: scripts/launch-mac.sh [options]

Options:
  --clean                 Run clean + build before launch
  --clean-only            Clean build artifacts only, then exit
  --clean-artifacts       Alias of --clean-only
  --deep-clean            With clean-only, remove full derived-data directories
  --target-only           With clean-only, do not sweep local DerivedData* directories
  --no-open               Build only, do not open app
  --derived-data <path>   Override DerivedData output path
  -h, --help              Show this help
EOF
}

is_path_within() {
  local path="${1%/}"
  local base="${2%/}"
  [[ -n "$base" ]] || return 1
  case "$path" in
    "$base"|"$base"/*) return 0 ;;
    *) return 1 ;;
  esac
}

is_safe_delete_path() {
  local path="$1"
  local allowed_root="$2"
  [[ -n "$path" ]] || return 1
  [[ "$path" != "/" ]] || return 1
  [[ "$path" != "$HOME" ]] || return 1
  [[ "$path" != "$ROOT_DIR" ]] || return 1
  is_path_within "$path" "$allowed_root" || return 1
  return 0
}

delete_path_if_exists() {
  local path="$1"
  local allowed_root="$2"
  [[ -e "$path" || -L "$path" ]] || return 0

  if ! is_safe_delete_path "$path" "$allowed_root"; then
    echo "Refusing to delete unsafe path: $path" >&2
    return 1
  fi

  rm -rf "$path"
}

clean_derived_data_path() {
  local path="$1"
  [[ -d "$path" ]] || return 0

  if [[ "$deep_clean" == true ]]; then
    delete_path_if_exists "$path" "$path"
    return 0
  fi

  local child=""
  while IFS= read -r child; do
    delete_path_if_exists "$child" "$path"
  done < <(find "$path" -mindepth 1 -maxdepth 1 -print)

  rmdir "$path" 2>/dev/null || true
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean)
      clean_build=true
      shift
      ;;
    --clean-only|--clean-artifacts)
      clean_only=true
      open_app=false
      shift
      ;;
    --deep-clean)
      deep_clean=true
      shift
      ;;
    --target-only)
      clean_local_derived=false
      shift
      ;;
    --no-open)
      open_app=false
      shift
      ;;
    --derived-data)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --derived-data" >&2
        exit 1
      fi
      DERIVED_DATA_PATH="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

build_args=(
  -project "$PROJECT_PATH"
  -scheme "$SCHEME"
  -destination "$DESTINATION"
  -derivedDataPath "$DERIVED_DATA_PATH"
  CODE_SIGNING_ALLOWED=NO
)

if [[ "$clean_only" == true ]]; then
  if ! xcodebuild "${build_args[@]}" clean; then
    echo "Warning: xcodebuild clean failed, continuing filesystem cleanup." >&2
  fi

  clean_derived_data_path "$DERIVED_DATA_PATH"
  if [[ "$clean_local_derived" == true ]]; then
    while IFS= read -r path; do
      [[ "${path%/}" == "${DERIVED_DATA_PATH%/}" ]] && continue
      clean_derived_data_path "$path"
    done < <(find "$ROOT_DIR" -maxdepth 1 -type d -name 'DerivedData*' -print)
  fi

  if [[ "$deep_clean" == true ]]; then
    echo "Clean finished (deep): $DERIVED_DATA_PATH"
  else
    echo "Clean finished: $DERIVED_DATA_PATH"
  fi
  exit 0
fi

if [[ "$clean_build" == true ]]; then
  xcodebuild "${build_args[@]}" clean build
else
  xcodebuild "${build_args[@]}" build
fi

app_path="$(find "$DERIVED_DATA_PATH/Build/Products" -maxdepth 3 -type d -name "${SCHEME}.app" | head -n 1)"
if [[ -z "$app_path" ]]; then
  echo "Build completed, but app bundle not found under $DERIVED_DATA_PATH/Build/Products" >&2
  exit 1
fi

echo "App bundle: $app_path"
if [[ "$open_app" == true ]]; then
  open "$app_path"
  echo "Launched."
else
  echo "Build finished (launch skipped)."
fi
