import SwiftUI

struct DeviceShakeViewModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                #if DEBUG
                showDebugMenu()
                #endif
            }
    }
    
    private func showDebugMenu() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }

        let vc = UIHostingController(rootView: DebugMenuView())
        vc.modalPresentationStyle = .formSheet
        window.rootViewController?.present(vc, animated: true)
    }
}

extension View {
    func onShake() -> some View {
        self.modifier(DeviceShakeViewModifier())
    }
}

