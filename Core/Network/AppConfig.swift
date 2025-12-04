import Foundation

enum AppConfig {
    static var baseURL: String {
        switch AppEnvironment.current {
        case .debug:
            return "https://stage.example.ru/"
        case .release:
            return "https://prod.example.ru/"
        }
    }

    static var name: String {
        AppEnvironment.current.rawValue.capitalized
    }
}

