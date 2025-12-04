import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    static var shared: AppDelegate?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = false
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if let error = error {
                print("❌ Ошибка получения разрешения: \(error.localizedDescription)")
            } else if granted {
                print("✅ Разрешение на уведомления предоставлено")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("❌ Разрешение на уведомления не предоставлено")
            }
        }
        
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("📩 Получено уведомление: \(userInfo)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Ошибка регистрации для удалённых уведомлений: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("📩 Получен пуш: \(userInfo)")
        
        if let title = userInfo["title"] as? String,
           let body = userInfo["body"] as? String,
           let deepLink = userInfo["clickAction"] as? String {
            showLocalNotification(title: title, body: body, deepLink: deepLink)
        }

        completionHandler(.newData)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🚀 Пуш-уведомление было нажато! userInfo: \(response.notification.request.content.userInfo)")

        let userInfo = response.notification.request.content.userInfo
        if let deepLink = userInfo["clickAction"] as? String ?? userInfo["deep_link"] as? String {
            print("🔗 Извлечён deepLink: \(deepLink)")
            handleDeepLink(deepLink)
        } else {
            print("❌ Ошибка: deepLink не найден в userInfo")
        }
        
        completionHandler()
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("✅ APNs Token установлен: \(deviceToken)")
        Task {
            do {
                let fcmToken = try await Messaging.messaging().token()
                if !fcmToken.isEmpty {
                    print("🔥 Получен FCM Token: \(fcmToken)")
                    UserDefaults.standard.setValue(fcmToken, forKey: "FCMToken")
                    putNewToken(token: fcmToken)
                }
            } catch {
                print("Ошибка при запросе FCM-токена: \(error.localizedDescription)")
            }
        }
    }

    func handleDeepLink(_ deepLink: String) {
        guard let url = URL(string: deepLink),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        
        let pathComponents = components.path.split(separator: "/").map(String.init)
        
        guard pathComponents.count >= 3 else {
            print("Not enough path components")
            return
        }
        
        let type = pathComponents[0]
        let id = pathComponents.last!
        var userInfo: [String: Any] = ["type": type, "id": id]
        
        if let queryItems = components.queryItems {
            for item in queryItems {
                userInfo[item.name] = item.value
            }
        }
        
        DispatchQueue.main.async {
            print("📢 Отправляем Notification с userInfo: \(userInfo)")
            NotificationCenter.default.post(name: .deepLinkNotification, object: nil, userInfo: userInfo)
        }
    }
}

