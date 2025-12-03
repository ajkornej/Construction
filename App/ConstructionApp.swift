import SwiftUI
import Kingfisher
import FirebaseCore

@main
struct ConstructionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .environmentObject(networkMonitor)
                .onShake()
        }
    }
}
