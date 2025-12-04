import Foundation
import SwiftUI

public struct LoginView: View {
    
    @Binding
    public var navigationPath: NavigationPath
    
    @State
    private var phoneNumber: String = "+7 "
    
    @State
    private var isPhoneValid: Bool = false
    
    @State
    private var isLoading: Bool = false
    
    @State
    private var isUserNotFound: Bool = false
    
    @FocusState
    private var keyboardFocused: Bool
    
    private let maxLength = 18
    
    @StateObject private var networkMonitor = NetworkMonitor()
    
    public var body: some View {
        VStack {
            Text("Введите номер телефона")
                .font(Fonts.Font_Callout)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, 16)
            
            ZStack {
                TextField("", text: $phoneNumber, prompt: Text("Введите ваш номер").foregroundColor(Colors.textFieldOverlayGray))
                    .autocapitalization(.none)
                    .keyboardType(.numberPad)
                    .foregroundColor(.black)
                    .disableAutocorrection(true)
                    .textContentType(.telephoneNumber)
                    .accentColor(Colors.orange)
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 40)) // Отступ справа для кнопки
                    .overlay(
                        RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(Colors.orange)
                    )
                    .cornerRadius(18)
                    .padding(.top, 4)
                    .onChange(of: phoneNumber) { newValue in
                                    phoneNumber = formatPhoneNumber(newValue)
                                    isPhoneValid = phoneNumber.count == maxLength
                                }
                    .focused($keyboardFocused)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            keyboardFocused = true
                        }
                    }
                
                // Крестик для очистки поля
                if !phoneNumber.isEmpty && phoneNumber != "+7 "  {
                    HStack {
                        Spacer() // Сдвигаем крестик вправо
                        Button(action: {
                            phoneNumber = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 16) // Отступ для кнопки
                        .padding(.top, 4)
                    }
                    .frame(height: 56) // Высота как у TextField
                }
            }
            if !networkMonitor.isConnected {
                Text("Нет подключения к интернету")
                    .font(Fonts.Font_Callout)
                    .foregroundColor(Color.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                
            } else {
                
                if isUserNotFound {
                    Text("Похоже, Вы не являетесь нашим клиентом")
                        .font(Fonts.Font_Callout)
                        .foregroundColor(Color.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 15)
                } else {
                    Rectangle()
                        .foregroundColor(Color.white)
                        .frame(height: 15)
                }
            }
                
            
            Spacer()
            
            Button(
                action: {
                    print(phoneNumber)
                    if isPhoneValid {
                        getCodeRequest { key in
                            guard let unwrappedKey = key else {
                                isUserNotFound = true
                                return
                            }
                            
                            // Навигируемся на экран подтверждения с параметрами
                            navigationPath.append(
                                ConfirmationDestination(phone: phoneNumber, key: unwrappedKey)
                            )
                        }
                    }
                }
            ) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                } else {
                    Text("Войти")
                        .font(Fonts.Font_Headline2)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
            }
            .background(isPhoneValid ? Colors.orange : Colors.textFieldOverlayGray)
            .cornerRadius(16)
            .padding(.bottom, 20)
            
        }
        .navigationTitle("Вход")
        .navigationBarTitleDisplayMode(.inline)
        .padding(.horizontal, 16)
        
    }
    
    func getCodeRequest(onKeyReady: @escaping (String?) -> Void) {
        isLoading = true
        
        let body = GetCodeRequest(phone: phoneNumber, type: "AUTHENTICATION")
        NetworkAccessor.shared.post("/authentication/getCode", body: body) { (result: Result<GetCodeResponse, Error>, statusCode: Int?) in
            isLoading = false
            switch result {
            case .success(let data):
                onKeyReady(data.key)
                print("data key  \(data.key)")
                isUserNotFound = false
            case .failure(let error):
                if let statusCode = statusCode {
                    switch statusCode {
                    case 404:
                        isUserNotFound = true
                        print("Похоже, Вы не являетесь нашим клиентом")
                        onKeyReady(nil)
                        print("error \(error)")
                    case 400:
                        print("Некорректный код")
                        onKeyReady(nil)
                    default:
                        print("Ошибка: \(error.localizedDescription)")
                        onKeyReady(nil)
                    }
                } else {
                    print("Ошибка: \(error.localizedDescription)")
                    onKeyReady(nil)
                }
            }
        }
    }

    
    func formatPhoneNumber(_ number: String) -> String {
            // Удаляем все символы, кроме цифр
            let cleanedNumber = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

            // Если поле очищено и пользователь начинает ввод с цифры, добавляем +7
            if cleanedNumber.isEmpty {
                return ""
            } else if cleanedNumber.count == 1 && cleanedNumber != "7" {
                return "+7 " + cleanedNumber
            }

            // Если начинается с 8, заменяем её на 7
            var formattedNumber = cleanedNumber
            if cleanedNumber.hasPrefix("8") {
                formattedNumber = "7" + cleanedNumber.dropFirst()
            }

            // Если уже введена 7 без +, добавляем +7
            if formattedNumber.hasPrefix("7") && !formattedNumber.hasPrefix("+7") {
                formattedNumber = "+7" + formattedNumber.dropFirst()
            }

            // Применяем маску
            formattedNumber = applyPhoneMask(to: formattedNumber)

            // Возвращаем отформатированный номер
            return formattedNumber
        }

    func applyPhoneMask(to number: String) -> String {
        let cleanedNumber = number.replacingOccurrences(of: "+", with: "")
        let mask = "+X (XXX) XXX XX-XX"
        var result = ""
        var index = cleanedNumber.startIndex

        for ch in mask where index < cleanedNumber.endIndex {
            if ch == "X" {
                result.append(cleanedNumber[index])
                index = cleanedNumber.index(after: index)
            } else {
                result.append(ch)
            }
        }

        return result
    }
}
