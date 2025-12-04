import Foundation
import SwiftUI
import FirebaseMessaging

public struct ConfirmationView: View {
    
    @Binding
    public var navigationPath: NavigationPath
    
    public var phoneNumber: String
    
    @State
    public var key : String
    
    @State
    private var confirmationCode: String = ""
    
    @State
    private var isCodeValid: Bool = true
    
    @FocusState
    private var isKeyboardFocused: Bool
    
    @State
    private var isRequestInProgress = false
    
    private let maxLength = 4
    
    private var formattedConfirmationCode: String {
        return confirmationCode.filter { $0 != " " }
    }
    
    @State
    private var remainingSeconds = 60
    
    @State
    private var isTimerRunning = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()
    
    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        
        // Для минут убираем ведущий ноль, если minutes == 0
        if minutes == 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    @State var Error404: Bool = false
    @State var Error400: Bool = false
    
    @State private var cursorBlink: Bool = false 
    
    public var body: some View {
        VStack {
            Text("Вам поступит звонок")
                .font(Fonts.Font_Headline1)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, 16)
            
            Text("на номер")
                .font(Fonts.Font_Headline1)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            
            HStack {
                ZStack {
                    Rectangle()
                        .frame(width: 36, height: 36)
                        .foregroundColor(Colors.orange)
                        .cornerRadius(100)
                    
                    Image("call_swg_white")
                        .frame(width: 14, height: 14)
                }
                
                Text(phoneNumber)
                    .font(Fonts.Font_Headline2)
                    .foregroundStyle(Colors.boldGray)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            HStack(spacing: 0) {
                ForEach(0..<maxLength, id: \.self) { index in
                    let character = index < confirmationCode.count ? Array(confirmationCode)[index] : " "
                    ZStack {
                        Text(String(character))
                            .font(Font.custom("Roboto", size: 40).weight(.medium))
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                        
                        // Добавляем курсор, если это текущая позиция ввода
                        if index == confirmationCode.count && isKeyboardFocused {
                            Rectangle()
                                .frame(width: 2, height: 30)
                                .foregroundColor(Colors.orange)
                                .opacity(cursorBlink ? 1 : 0) // Мигание курсора
                                .animation(.easeInOut(duration: 0.5).repeatForever(), value: cursorBlink)
                        }
                    }
                }
            }
            .frame(width: 220)
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(Colors.orange))
            .cornerRadius(18)
            .padding(.top, 72)
            .background(
                TextField("", text: $confirmationCode, prompt: Text("").foregroundColor(.gray))
                    .font(Font.custom("Roboto", size: 1).weight(.medium)) // Оставляем маленький шрифт для скрытия
                    .autocapitalization(.none)
                    .keyboardType(.numberPad)
                    .foregroundColor(.clear) // Скрываем текст в TextField
                    .disableAutocorrection(true)
                    .accentColor(Colors.orange)
                    .multilineTextAlignment(.center)
                    .frame(width: 220, height: 40)
                    .opacity(0.01) // Практически невидим
                    .focused($isKeyboardFocused)
                    .onChange(of: confirmationCode) { newValue in
                        isCodeValid = true
                        if newValue.count > maxLength {
                            confirmationCode = String(newValue.prefix(maxLength))
                        }
                        if newValue.count == maxLength && !isRequestInProgress {
                            isRequestInProgress = true
                            checkCodeRequest { success in
                                if success {
                                    Task {
                                        let fcmToken = try await Messaging.messaging().token()
                                        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                            print("🔄 Отправляем токен перед переходом на главный экран...")
                                            appDelegate.putNewToken(token: fcmToken)
                                        }
                                        
                                        DispatchQueue.main.async {
                                            navigationPath.append(Destination.mainview) // Только после отправки FCM-токена
                                        }
                                    }
                                } else {
                                    isCodeValid = false
                                    
                                }
                                isRequestInProgress = false
                            }
                        }
                    }
            )
            .onAppear {
                isKeyboardFocused = true // Фокус на клавиатуре при появлении
                cursorBlink = true // Запускаем мигание курсора
            }
            .onChange(of: isKeyboardFocused) { newValue in
                cursorBlink = newValue // Включаем/выключаем курсор в зависимости от фокуса
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isKeyboardFocused = true
                }
            }
            
            if Error400 {
                Text("Некорректный код")
                    .font(Fonts.Font_Callout)
                    .foregroundColor(Color.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if Error404 {
                Text("Похоже, Вы не являетесь нашим клиентом")
                    .font(Fonts.Font_Callout)
                    .foregroundColor(Color.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text("Введите последние 4 цифры")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                
                Text("входящего номера")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer()
            
            Button(
                action: {
                    if !isTimerRunning {
                        getCodeRequest { key in
                            guard let unwrappedKey = key else {
                                return
                            }
                            
                            self.key = unwrappedKey
                        }
                    }
                }
            ) {
                if isTimerRunning {
                    Text("Запросить повторно через \(formattedTime)")
                        .font(Fonts.Font_Callout)
                        .foregroundColor(Colors.boldGray)
                        .cornerRadius(10)
                } else {
                    Text("Запросить повторно")
                        .font(Fonts.Font_Callout)
                        .foregroundColor(Colors.orange)
                        .cornerRadius(10)
                }
            }
            .onReceive(timer) { _ in
                if isTimerRunning {
                    if remainingSeconds > 0 {
                        remainingSeconds -= 1
                    } else {
                        stopTimer()
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .onAppear{
            startTimer()
            
//            Messaging.messaging().apnsToken = deviceToken
        }
    }
    
    func getCodeRequest(onKeyReady: @escaping (String?) -> Void) {
        startTimer()
        let body = GetCodeRequest(phone: phoneNumber, type: "AUTHENTICATION")
        
        NetworkAccessor.shared.post("/authentication/getCode", body: body) { (result: Result<GetCodeResponse,Error>, statusCode: Int?) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    onKeyReady(data.key)
                    Error404 = false
                    Error400 = false
                    print("Sucsess reg")
                case .failure(let error):
                    if let statusCode = statusCode {
                        switch statusCode {
                        case 404:
                            print("Похоже, Вы не являетесь нашим клиентом")
                            Error404 = true
                            Error400 = false
                        case 400:
                            print("Некорректный код")
                            Error404 = false
                            Error400 = true
                        default:
                            print("Ошибка: \(error.localizedDescription)")
                            Error404 = false
                            Error400 = false
                        }
                    } else {
                        print("Ошибка: \(error.localizedDescription)")
                        
                    }
                }
            }
        }
    }
    
    func checkCodeRequest(completion: @escaping (Bool) -> Void) {
        let checkCodeBody = CheckCodeRequest(phone: phoneNumber, key: key, code: confirmationCode)
        
        print("Key: \(key), Confirmation Code: \(confirmationCode)")

        NetworkAccessor.shared.post("/authentication/checkCode", body: checkCodeBody) { (result: Result<AuthenticationResponse, Error>, statusCode: Int?) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    AccessTokenHolder.shared.saveAccessToken(data.accessToken)
                    UserDefaults.standard.set(data.user.isEmployee, forKey: "isEmployee")
                    
                    let id: String = UUID().uuidString
                    
                    UserDefaults.standard.set(id, forKey: "sessionId")
                    UserDefaults.standard.synchronize()
                    
                    saveAuthenticationResponse(data)
                    Error404 = false
                    Error400 = false
                    
                    Task { @MainActor in
                        do {
                            
                            if Messaging.messaging().apnsToken == nil {
                                print("⚠️ APNS Token еще не установлен. Ожидаем...")
                                // Ждём, пока токен появится, используя NotificationCenter
                               
                            }
                            let fcmToken = try await Messaging.messaging().token()
                            
                            if !fcmToken.isEmpty {
                                print("🔥 Получен FCM Token (checkCodeRequest): \(fcmToken)")
                                UserDefaults.standard.setValue(fcmToken, forKey: "FCMToken")

                                if let appDelegate = AppDelegate.shared {
                                    print("✅ AppDelegate доступен")
                                    appDelegate.putNewToken(token: fcmToken)
                                } else {
                                    print("❌ AppDelegate не найден")
                                }
                            } else {
                                print("⚠️ FCM-токен отсутствует при первой авторизации")
                            }

                            // Дожидаемся завершения перед переходом
                            DispatchQueue.main.async {
                                completion(true) // Навигация запускается только после завершения всех операций
                            }
                        } catch {
                            print("Ошибка при запросе FCM-токена (checkCodeRequest): \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                completion(true) // Навигация запускается даже при ошибке, чтобы не зависло приложение
                                navigationPath.append(Destination.mainview)
                            }
                        }
                    }
                case .failure(let error):
                    if let statusCode = statusCode {
                        switch statusCode {
                        case 404:
                            print("Похоже, Вы не являетесь нашим клиентом")
                            Error404 = true
                            Error400 = false
                        case 400:
                            print("Некорректный код")
                            Error404 = false
                            Error400 = true
                        default:
                            print("Ошибка: \(error.localizedDescription)")
                            Error404 = false
                            Error400 = false
                        }
                    } else {
                        print("Ошибка: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func saveAuthenticationResponse(_ authResponse: AuthenticationResponse) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(authResponse)
            UserDefaults.standard.set(data, forKey: "authResponse")
        } catch {
            print("Ошибка при сохранении AuthenticationResponse: \(error.localizedDescription)")
        }
    }
    
    func startTimer() {
        isTimerRunning = true
        remainingSeconds = 60
    }
    
    func stopTimer() {
        isTimerRunning = false
    }
}

// Описание направления с параметрами
struct ConfirmationDestination : Hashable {
    let phone: String
    let key: String
}

