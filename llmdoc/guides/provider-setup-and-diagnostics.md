# Guide: Provider Setup and Diagnostics

## Configure Provider

1. Open provider settings from the toolbar (macOS inspector).
2. Create or edit a provider profile.
3. Save API key (stored in Keychain only).
4. Activate the provider.

## Diagnostics

1. Trigger diagnostics from provider settings.
2. Probe uses `ProviderConnectivityProbe` against `<baseURL>/models`.
3. Review status, HTTP code, latency, and message.

## Common Failure Modes

- Missing API key in Keychain account.
- Invalid base URL.
- Malformed extra headers JSON.
- Authorization failure returned by provider.
