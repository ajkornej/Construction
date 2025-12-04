#if DEBUG
import UIKit
import SwiftUI

class ShakeWindow: UIWindow {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            showDebugMenu()
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
#endif
