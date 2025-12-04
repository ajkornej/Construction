//
//  costCalculation.swift
//  stroymir
//
//  Created by Корнеев Александр on 01.04.2024.
//

import SwiftUI

struct costCalculation: View {
    
    @Binding var navigationPath: NavigationPath
    @State private var currentStep = 1
    @State var roomArea: String = ""
    @State private var isOn = false
    @FocusState var keyboardFocused: Bool
    
    let totalStep = 6
    let maxLength = 400
    
    @State private var buildingRequest = CalculatorRequest(objectType: "", square: 0, designType: "", dateType: "", giftType: "", communicationType: "", phone: "")
    
    let ObjectTypeData = [
            ("apartNew", "Новостройка", "new"),
            ("apartSecondary", "Вторичное жилье", "SECONDARY_BUILDING"),
            ("apartCottage", "Загородный\n        дом", "HOUSE"),
            ("apartOffice", "Коммерческое\n   помещение", "OFFICE")
        ]
    @State var selectedObjectType: String?
    
    let giftTypeData = [
            ("saling", "  Скидка до 10% \n  на материалы", "DISCOUNT_10_ON_MATERIALS"),
            ("cleaning", "       Клининг \n после ремонта", "CLEANING"),
            ("vacuum", "Робот-пылесос", "VACUUM_CLEANER")
        ]
    @State var selectedGiftTyp: String?
   
    @State private var designSelection: String = ""
    @State private var dateSelection: String = ""
    @State private var communicationTypeSelection: String = ""
    @State private var phoneNumberCalculate: String = "+7 "
    @State var isPhoneValid: Bool = false

    var body: some View {
        
        ProgressView(value: Double(currentStep), total: Double(totalStep))
            .progressViewStyle(LinearProgressViewStyle())
            .tint(Colors.orange)
        
        VStack {
            
            if currentStep == 1 {
                
                VStack {
                    
                    Text("Где вы планируете делать")
                        .font(Fonts.Font_Headline1)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Text("ремонт?")
                        .font(Fonts.Font_Headline1)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(ObjectTypeData, id: \.0) { imageName, text, idd in
                            ZStack{
                                Rectangle()
                                    .frame(width: 170, height: 180)
                                    .foregroundColor(Colors.lightGray2)
                                    .cornerRadius(20)
                                    
                                VStack{
                                    Image(imageName)
                                        .resizable()
                                        .frame(width: 170, height: 124.32)
                                    
                                    Text(text)
                                        .font(Fonts.Font_Body)
                                        .frame(maxHeight: .infinity, alignment: .top)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(selectedObjectType == idd ? Colors.orange : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedObjectType = idd
                                buildingRequest.objectType = idd
                            }
                        }
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    Button(action: {
                        // Переход к следующему шагу
                        if selectedObjectType != nil {
                            withAnimation {
                                currentStep += 1
                            }
                            print(selectedObjectType!)
                        }
                    }) {
                        Text("Далее")
                            .font(Fonts.Font_Headline2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .background(selectedObjectType != nil ? Colors.orange : Colors.textFieldOverlayGray)
                    .cornerRadius(16)
                    .padding(.bottom, 20)
                }
                
            }
            
            if currentStep == 2 {
                
                VStack{
                    
                    Text("Какая у Вас общая площадь")
                        .font(Fonts.Font_Headline1)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Text("объекта?")
                        .font(Fonts.Font_Headline1)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    Text("Площадь объекта")
                        .font(Fonts.Font_Callout)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 16)
                    
                    ZStack{
                        TextField("",text: $roomArea, prompt: Text("Введите площадь").foregroundColor(Colors.textFieldOverlayGray))
                            .autocapitalization(.none)
                            .keyboardType(.numberPad)
                            .foregroundColor(.black)
                            .disableAutocorrection(true)
                            .accentColor(Colors.orange)
                            .textContentType(.emailAddress)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                            .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(Colors.orange))
                            .cornerRadius(18)
                            .padding(.top, 2)
                            .focused($keyboardFocused)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    keyboardFocused = true
                                }
                            }
                        
                        // Крестик для очистки поля
                        if !roomArea.isEmpty {
                            HStack {
                                Spacer() // Сдвигаем крестик вправо
                                Button(action: {
                                    roomArea = ""
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
                    
                    Text("Площадь должна быть от 1 до 400 м²")
                        .font(Fonts.Font_Footnote)
                        .foregroundColor(Colors.textFieldOverlayGray)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 2)
    
                    Spacer()
                    
                    // Buttons
                    HStack{
                        Button(action: {
                            keyboardFocused = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                        }) {
                            Text("Назад")
                                .font(Fonts.Font_Headline2)
                                .foregroundColor(Colors.orange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Colors.orange, lineWidth: 2)
                        )
                        .padding(.bottom, 20)
                        
                        Button(action: {
                            if roomArea != "" && roomArea.count < 4 && (Double(roomArea) ?? 0 < 401) && roomArea != "0" && roomArea != "00" && roomArea != "000" {
                                withAnimation {
                                    buildingRequest.square = Double(roomArea) ?? 0
                                    currentStep += 1
                                }
                                print(buildingRequest.square)
                            }
                        }) {
                            Text("Далее")
                                .font(Fonts.Font_Headline2)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .background((roomArea != "" && roomArea.count < 4 && (Double(roomArea) ?? 0 < 401) && roomArea != "0" && roomArea != "00" && roomArea != "000") ? Colors.orange : Colors.textFieldOverlayGray)
                        .cornerRadius(16)
                        .padding(.bottom, 20)
                    }
                }
            }
            
            if currentStep == 3 {
                
                Text("Потребуется ли вам помощь с")
                    .font(Fonts.Font_Headline1)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                Text("планировкой или дизайном?")
                    .font(Fonts.Font_Headline1)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                
                    
                VStack(alignment: .leading, spacing: 16) {
                    // Три чекбокса для выбора типа дизайна
                    CheckBoxView(text: "Да, потребуется дизайн-проект", isChecked: designSelection == "NEED_DESIGN") {
                        designSelection = "NEED_DESIGN"
                        buildingRequest.designType = "NEED_DESIGN"
                    }
                    CheckBoxView(text: "Дизайн уже есть", isChecked: designSelection == "DESIGN_EXISTS") {
                        designSelection = "DESIGN_EXISTS"
                        buildingRequest.designType = "DESIGN_EXISTS"
                    }
                    CheckBoxView(text: "Нет, спасибо", isChecked: designSelection == "NO") {
                        designSelection = "NO"
                        buildingRequest.designType = "NO"
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, 16)
                
                Spacer()
                
                // Buttons
                HStack{
                    Button(action: {
                        withAnimation {
                            currentStep -= 1
                        }
                    }) {
                        Text("Назад")
                            .font(Font.custom("Inter", size: 16).weight(.bold))
                            .foregroundColor(Colors.orange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Colors.orange, lineWidth: 2)
                    )
                    .padding(.bottom, 20)
                    
                    Button(action: {
                        if designSelection != "" {
                            withAnimation {
                                currentStep += 1
                            }
                            print(buildingRequest.designType)
                        }
                    }) {
                        Text("Далее")
                            .font(Font.custom("Inter", size: 16).weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .background(designSelection != "" ? Colors.orange : Colors.textFieldOverlayGray)
                    .cornerRadius(16)
                    .padding(.bottom, 20)
                }
                
            }
            
            if currentStep == 4 {

                VStack{
                    // У вас уже есть дизайн-проект?
                    Text("Когда вы планируете начать")
                        .font(Fonts.Font_Headline1)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Text("ремонт?")
                        .font(Fonts.Font_Headline1)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Три чекбокса для выбора типа дизайна
                        CheckBoxView(text: "В течение недели", isChecked: dateSelection == "DURING_WEEK") {
                            dateSelection = "DURING_WEEK"
                            buildingRequest.dateType = "DURING_WEEK"
                        }
                        CheckBoxView(text: "В течение месяца", isChecked: dateSelection == "DURING_MONTH") {
                            dateSelection = "DURING_MONTH"
                            buildingRequest.dateType = "DURING_MONTH"
                        }
                        CheckBoxView(text: "В течение 2 месяцев", isChecked: dateSelection == "DURING_2_MONTHS") {
                            dateSelection = "DURING_2_MONTHS"
                            buildingRequest.dateType = "DURING_2_MONTHS"
                        }
                        CheckBoxView(text: "Пока не определились", isChecked: dateSelection == "NOT_DECIDED") {
                            dateSelection = "NOT_DECIDED"
                            buildingRequest.dateType = "NOT_DECIDED"
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // buttons
                    HStack{
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Назад")
                                .font(Font.custom("Inter", size: 16).weight(.bold))
                                .foregroundColor(Colors.orange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Colors.orange, lineWidth: 2)
                        )
                        .padding(.bottom, 20)
                        
                        Button(action: {
                            if dateSelection != "" {
                                print(buildingRequest.designType, buildingRequest.dateType)
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }) {
                            Text("Далее")
                                .font(Font.custom("Inter", size: 16).weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .background(dateSelection != "" ? Colors.orange : Colors.textFieldOverlayGray)
                        .cornerRadius(16)
                        .padding(.bottom, 20)
                    }
                }
            }
            
            if currentStep == 5 {
                VStack{
                    Text("Выберите свой подарок к")
                        .font(Fonts.Font_Headline1)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Text("ремонту")
                        .font(Fonts.Font_Headline1)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(giftTypeData, id: \.0) { imageName, text, idd in
                            ZStack{
                                Rectangle()
                                    .frame(width: 170, height: 180)
                                    .foregroundColor(Colors.lightGray2)
                                    .cornerRadius(20)
                                
                                VStack{
                                    Image(imageName)
                                        .resizable()
                                        .frame(width: 170, height: 124.32)
                                    
                                    Text(text)
                                        .font(Fonts.Font_Body)
                                        .frame(maxHeight: .infinity, alignment: .top)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(selectedGiftTyp == idd ? Colors.orange : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedGiftTyp = idd
                                buildingRequest.giftType = idd
                            }
                        }
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    HStack{
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Назад")
                                .font(Font.custom("Inter", size: 16).weight(.bold))
                                .foregroundColor(Colors.orange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Colors.orange, lineWidth: 2)
                        )
                        .padding(.bottom, 20)
                        
                        Button(action: {
                            // Переход к следующему шагу
                            if selectedGiftTyp != nil {
                                withAnimation {
                                    currentStep += 1
                                }
                                print(selectedGiftTyp!)
                            }
                        }) {
                            Text("Далее")
                                .font(Fonts.Font_Headline2)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                        .background(selectedGiftTyp != nil ? Colors.orange : Colors.textFieldOverlayGray)
                        .cornerRadius(16)
                        .padding(.bottom, 20)
                    }
                }
            }
            
            if currentStep == 6 {
                VStack{
                    Text("Куда выслать расчёт")
                        .font(Fonts.Font_Headline1)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Text("стоимости?")
                        .font(Fonts.Font_Headline1)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Три чекбокса для выбора типа дизайна
                        CheckBoxView(text: "WhatsApp", isChecked: communicationTypeSelection == "WHATS_APP") {
                            communicationTypeSelection = "WHATS_APP"
                            buildingRequest.communicationType = "WHATS_APP"
                        }
                        CheckBoxView(text: "Telegram", isChecked: communicationTypeSelection == "TELEGRAM") {
                            communicationTypeSelection = "TELEGRAM"
                            buildingRequest.communicationType = "TELEGRAM"
                        }
                        CheckBoxView(text: "Позвоните мне, есть вопрос", isChecked: communicationTypeSelection == "CALL") {
                            communicationTypeSelection = "CALL"
                            buildingRequest.communicationType = "CALL"
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 20)
                    
                    Text("Введите ваш номер телефона")
                        .font(Fonts.Font_Callout)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 24)
                    
                    ZStack {
                        TextField("", text: $phoneNumberCalculate, prompt: Text("Номер телефона").foregroundColor(Colors.textFieldOverlayGray))
                            .autocapitalization(.none)
                            .keyboardType(.numberPad)
                            .foregroundColor(.black)
                            .disableAutocorrection(true)
                            .accentColor(Colors.orange)
                            .textContentType(.telephoneNumber)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 40)) // Отступ справа для кнопки
                            .overlay(
                                RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(Colors.orange)
                            )
                            .cornerRadius(18)
                            .padding(.top, 4)
                            .onChange(of: phoneNumberCalculate) { newValue in
                                phoneNumberCalculate = formatPhoneNumber(newValue)
                                            isPhoneValid = phoneNumberCalculate.count == maxLength
                                        }
                            .focused($keyboardFocused)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    keyboardFocused = true
                                }
                            }
                        
                        // Крестик для очистки поля
                        if !phoneNumberCalculate.isEmpty && phoneNumberCalculate != "+7 "  {
                            HStack {
                                Spacer() // Сдвигаем крестик вправо
                                Button(action: {
                                    phoneNumberCalculate = ""
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
                    
                    Spacer()
                    
                    Button(action: {
                        
                        if phoneNumberCalculate.count == 18 && buildingRequest.communicationType != "" {
                            
                            buildingRequest.objectType = selectedObjectType ?? ""
                            buildingRequest.square = Double(roomArea) ?? 0
                            buildingRequest.designType = designSelection
                            buildingRequest.dateType = dateSelection
                            buildingRequest.giftType = selectedGiftTyp ?? ""
                            buildingRequest.communicationType = communicationTypeSelection
                            buildingRequest.phone = phoneNumberCalculate
                            
                            // Вызов функции calculateRequest
                            calculateRequest(buildingRequest: buildingRequest) { success in
                                if success {
                                    print("Request successful")
                                } else {
                                    print("Request failed")
                                }
                            }
                            navigationPath.append(Destination.firstview)
                        }
                    }) {
                        Text("Получить расчёт")
                            .font(Font.custom("Inter", size: 16).weight(.bold))
                            .foregroundColor(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .background((phoneNumberCalculate.count == 18 && buildingRequest.communicationType != "") ? Colors.orange : Colors.textFieldOverlayGray)
                    .cornerRadius(16)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Расчёт стоимости")
        .navigationBarTitleDisplayMode(.inline)
        .padding(.horizontal, 16)
        .padding(.top, 36)
    }
}


struct CheckBoxView: View {
    let text: String
    let isChecked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(isChecked ? "checkFILL" : "check")
                    .resizable()
                    .frame(width: 24, height: 24)
                Text(text)
                    .font(Fonts.Font_Body)
            }
        }
        .foregroundColor(.primary)
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
    let mask = "+X (XXX) XXX-XX-XX"
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

func calculateRequest(buildingRequest: CalculatorRequest, completion: @escaping (Bool) -> Void) {
    // Создание URL
    guard let url = URL(string: "\(AppConfig.baseURL)/calculations") else {
        print("Invalid URL")
        completion(false)
        return
    }
    
    // Создание тела запроса из buildingRequest
    let requestBody = ["objectType": buildingRequest.objectType,
                       "square": buildingRequest.square,
                       "designType": buildingRequest.designType,
                       "dateType": buildingRequest.dateType,
                       "giftType": buildingRequest.giftType,
                       "communicationType": buildingRequest.communicationType,
                       "phone": buildingRequest.phone ] as [String : Any]
    
    // Сериализация тела запроса в JSON
    guard let requestBodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
        print("Failed to serialize request body")
        completion(false)
        return
    }
    
    // Создание запроса
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = requestBodyData
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Отправка запроса
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Request error: \(error)")
            completion(false)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid HTTP response")
            completion(false)
            return
        }
        
        let statusCode = httpResponse.statusCode
        print("Response status code: \(statusCode)")
        
        if let data = data {
            let responseString = String(data: data, encoding: .utf8)
            print("Response Data: \(responseString ?? "")")
            
            // Обработка ответа и вызов completion
            // Например, в зависимости от содержания ответа можно установить completion(true) или completion(false)
        }
    }
    .resume()
}
