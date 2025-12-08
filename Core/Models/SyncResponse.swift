//
//  SyncResponse.swift
//  Construction
//
//  Created by Корнеев Александр on 08.12.2025.
//

import Foundation

// Модель ответа синхронизации данных пользователя
struct SyncResponse: Decodable {
    var user: FullUserResponse
    var permissions: [String]
}

