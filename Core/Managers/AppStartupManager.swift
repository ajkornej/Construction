//
//  AppStartupManager.swift
//  Construction
//
//  Created by Корнеев Александр on 08.12.2025.
//

import Foundation

// Менеджер инициализации приложения
// Обрабатывает логику первого запуска и очистки данных
final class AppStartupManager {
    
    // Обрабатывает первый запуск приложения после установки
    // - Note: Очищает Keychain при первом запуске для предотвращения
    //         использования устаревших токенов от предыдущей установки
    static func handleFirstLaunch() {
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: UserDefaultsKeys.hasLaunchedBefore) {
            // Первый запуск - очищаем Keychain
            AccessTokenHolder.shared.clearAccessToken()
            
            // Устанавливаем флаг
            userDefaults.set(true, forKey: UserDefaultsKeys.hasLaunchedBefore)
            userDefaults.synchronize()
        }
    }
}

