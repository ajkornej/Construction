//
//  Error.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 28.01.2025.
//

import Foundation

enum ApiError: Error {
    case invalidUrl
    case networkError(_ code: String)
    
    var localizedDescription: String {
        switch self {
        case .invalidUrl:
            "Некорректный Url"
        case .networkError(let code):
            "Ошибка сервера \(code)"
        }
    }
}
