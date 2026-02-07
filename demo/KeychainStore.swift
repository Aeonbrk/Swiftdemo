import Foundation
import Security

enum KeychainStoreError: Error {
  case unexpectedStatus(OSStatus)
  case invalidData
}

enum KeychainStore {
  static let llmService = "com.oian.demo.llm"

  static func setPassword(_ password: String, service: String, account: String) throws {
    let data = Data(password.utf8)

    let baseQuery: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: account
    ]

    let status = SecItemCopyMatching(baseQuery as CFDictionary, nil)
    if status == errSecSuccess {
      let attributesToUpdate: [CFString: Any] = [
        kSecValueData: data
      ]
      let updateStatus = SecItemUpdate(
        baseQuery as CFDictionary, attributesToUpdate as CFDictionary)
      guard updateStatus == errSecSuccess else {
        throw KeychainStoreError.unexpectedStatus(updateStatus)
      }
      return
    }

    guard status == errSecItemNotFound else { throw KeychainStoreError.unexpectedStatus(status) }

    var addQuery = baseQuery
    addQuery[kSecValueData] = data
    let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
    guard addStatus == errSecSuccess else { throw KeychainStoreError.unexpectedStatus(addStatus) }
  }

  static func getPassword(service: String, account: String) throws -> String? {
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: account,
      kSecReturnData: true,
      kSecMatchLimit: kSecMatchLimitOne
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw KeychainStoreError.unexpectedStatus(status) }

    guard let data = item as? Data else { throw KeychainStoreError.invalidData }
    guard let password = String(data: data, encoding: .utf8) else {
      throw KeychainStoreError.invalidData
    }
    return password
  }

  static func deletePassword(service: String, account: String) throws {
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: account
    ]

    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainStoreError.unexpectedStatus(status)
    }
  }

  static func hasPassword(service: String, account: String) -> Bool {
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: account,
      kSecReturnData: false,
      kSecMatchLimit: kSecMatchLimitOne
    ]

    let status = SecItemCopyMatching(query as CFDictionary, nil)
    return status == errSecSuccess
  }
}
