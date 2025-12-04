//
//  AppEnvironment.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 03.04.2025.
//

import Foundation

enum AppEnvironment: String, CaseIterable {
    case debug
    case release

    static var current: AppEnvironment {
        if let saved = UserDefaults.standard.string(forKey: "AppEnvironment"),
           let env = AppEnvironment(rawValue: saved) {
            return env
        }

#if DEBUG
        return .debug
#else
        return .release
#endif
    }

    static func set(_ env: AppEnvironment) {
        UserDefaults.standard.set(env.rawValue, forKey: "AppEnvironment")
    }
}
