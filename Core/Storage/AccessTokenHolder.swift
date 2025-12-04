import Foundation

class AccessTokenHolder {
    
    static let shared = AccessTokenHolder()
    
    private let accessTokenKey = "AccessToken"
    
    func saveAccessToken(_ token: String) {
        if let data = token.data(using: .utf8) {
            KeychainStorage.save(key: accessTokenKey, data: data)
        }
    }
    
    func getAccessToken() -> String? {
        if let data = KeychainStorage.retrieve(key: accessTokenKey) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func clearAccessToken() {
        KeychainStorage.delete(key: accessTokenKey)
    }
}
