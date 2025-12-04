//
//  DebugMenuView.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 03.04.2025.
//

import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedEnvironment = AppEnvironment.current

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("🌐 Окружение")) {
                    Picker("Окружение", selection: $selectedEnvironment) {
                        ForEach(AppEnvironment.allCases, id: \.self) { env in
                            Text(env.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button("💾 Применить окружение: \(selectedEnvironment.rawValue.capitalized)") {
                        AppEnvironment.set(selectedEnvironment)
                        print("✅ Переключено на: \(AppConfig.name)")
                    }
                }

                Section(header: Text("⚙️ Прочее")) {
                    Button("🔁 Сбросить UserDefaults") {
                        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                    }

                    Button("🔐 Показать токен") {
                        print("Token: \(UserDefaults.standard.string(forKey: "authToken") ?? "nil")")
                    }

                    Button("❌ Закрыть") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("🛠 Debug Menu")
        }
    }
}
