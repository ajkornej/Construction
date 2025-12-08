//
//  OpenObject.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 27.09.2024.
//

import SwiftUI

enum OpenObjectSheetType: Identifiable {
    case typeSheet
    case filePickerOpen

    // Реализация протокола Identifiable
    var id: String {
        switch self {
        case .filePickerOpen:
            return "filePickerOpen"
        case .typeSheet:
            return "typeSheet"
        }
    }
}

struct OpenObject: View {
    
    @Binding var tappedObjectId: String
    @Binding var navigationPath: NavigationPath
    
    @State var startDate: String = ""
    @State var endDate: String = ""
    @State var startDateError: Bool = false
    @State var endDateEmpty: Bool = false
    
    @State private var selectedStartDate = Date()
    @State private var selectedStartDateEmpty: Bool = false
    
    @State private var selectedEndDate: Date? = nil // Опциональная дата
    
    @State var selectedEndDateError: Bool = false
    
    @State private var selectedDocument: URL?
    
    @Binding var generatedPDFURL: URL? // Передаем сюда PDF
    
    @State private var showingDocumentPicker = false
    @State var selectedDocumentEmpty:  Bool = false
    
    @State private var documentPrice: String = ""
    @State private var documentPriceEmpty: Bool = false
    
    @State var IsUploadInProcess: Bool = false
    
    @Binding var needsRefresh: Bool
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var dataResponseObjectAll: [ObjectResponse]
    
    @Binding var capturedMedia: [CapturedMedia]
    
    @State private var authResponse: AuthenticationResponse?
    
    @State private var isDatePickerActive = false
    
    @State private var showDatePicker = false
    

    @State var openObjectBottomSheet = false
    
    @State private var activeSheetOpenObject: OpenObjectSheetType?

    @Binding var capturedMediaDoc: [CapturedMediaDocument]
    
    @State private var isDatePickerPresented = false
    
    @State private var isEndDatePickerPresented = false

    
    var body: some View {
        ZStack {
            VStack{
                
                Text("Дата начала")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)

                ZStack {
                    // Отображаем выбранную дату или placeholder
                    HStack {
                        Text(selectedStartDateEmpty ? "Выберите дату" : dateFormatter.string(from: selectedStartDate))
                            .foregroundColor(selectedStartDateEmpty ? .gray : .black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        Image("calendar_month_FILL0_wght400_GRAD0_opsz24")
                            .foregroundColor(!selectedStartDateEmpty ? Colors.textFieldOverlayGray : Color.red)
//                            .padding(.trailing, 16)
                    }
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .background(Color.white) // Можно настроить фон
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .inset(by: 1)
                            .stroke(!selectedStartDateEmpty ? Colors.textFieldOverlayGray : Color.red)
                    )
                    .cornerRadius(18)
                    .contentShape(Rectangle()) // Делает всю область кликабельной
                    .onTapGesture {
                        isDatePickerPresented.toggle() // Открываем DatePicker по тапу
                    }
                }
                .sheet(isPresented: $isDatePickerPresented) {
                    // Модальное представление DatePicker
                    VStack {
                        DatePicker("", selection: $selectedStartDate, displayedComponents: .date)
                            .datePickerStyle(.wheel) // Можно использовать .compact или .graphical
                            .labelsHidden()
                            .accentColor(.white)
                            .tint(.white)
                            .foregroundColor(.white)
                            .colorMultiply(.white)
                            .padding()
                        
                        Button(action: {
                            startDate = dateFormatter.string(from: selectedStartDate)
                            isDatePickerPresented = false
                        }, label: {
                            Text("Готово")
                                .foregroundColor(.orange)
                        })
                        .padding()
                    }
                    .presentationDetents([.medium]) // Ограничиваем высоту модального окна
                }

                Text("Дата завершения")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)

                ZStack {
                    // Отображаем дату или плейсхолдер
                    HStack {
                        Text(selectedEndDate != nil ? dateFormatter.string(from: selectedEndDate!) : "Введите дату завершения")
                            .foregroundColor(selectedEndDate != nil ? .primary : Colors.textFieldOverlayGray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                        
                        if selectedEndDate != nil {
                            Button(action: {
                                selectedEndDate = nil
                                endDate = ""
                            }) {
                                Image("close")
                                    .foregroundColor(Colors.textFieldOverlayGray)
                            }
                        } else {
                            Image("calendar_month_FILL0_wght400_GRAD0_opsz24")
                                .foregroundColor(Color.gray)
                        }
                    }
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .inset(by: 1)
                            .stroke( Colors.textFieldOverlayGray)
                    )
                    .cornerRadius(18)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isEndDatePickerPresented.toggle()
                    }
                }
                .sheet(isPresented: $isEndDatePickerPresented) {
                    VStack {
                        DatePicker("",
                                  selection: Binding(
                                    get: { selectedEndDate ?? Date() },
                                    set: { selectedEndDate = $0 }
                                  ),
                                  in: selectedStartDate...,
                                  displayedComponents: .date)
                            .datePickerStyle(.wheel) // Можно заменить на .compact или .graphical
                            .labelsHidden()
                            .accentColor(.white)
                            .tint(.white)
                            .foregroundColor(.white)
                            .colorMultiply(.white)
                            .padding()
                        
                        Button(action: {
                            if let date = selectedEndDate {
                                endDate = dateFormatter.string(from: date)
                            }
                            isEndDatePickerPresented = false
                        }, label: {
                            Text("Готово")
                                .foregroundColor(.orange)
                        })
                        .padding()
                    }
                    .presentationDetents([.medium])
                }

                Text("Договор")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)

                if let document = selectedDocument {
                    ZStack{
                        Text("\(document.lastPathComponent)")
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                            .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(Colors.textFieldOverlayGray))
                            .cornerRadius(18)
                            .padding(.top, -2)
                            .onTapGesture {
                                activeSheetOpenObject = .typeSheet
                            }
                        HStack {
                            Spacer()
                            
                            Image("attach_file")
                                .padding(.horizontal, 16)
                                .onTapGesture {
                                    activeSheetOpenObject = .typeSheet
                                }
                        }
                    }
                } else if let generatedPDF = generatedPDFURL {
                    ZStack{
                        Text("\(generatedPDF.lastPathComponent)")
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                            .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(Colors.textFieldOverlayGray))
                            .cornerRadius(18)
                            .padding(.top, -2)
                            .onTapGesture {
                                activeSheetOpenObject = .typeSheet
                            }
                        HStack {
                            Spacer()
                            
                            Image("attach_file")
                                .padding(.horizontal, 16)
                                .onTapGesture {
                                    activeSheetOpenObject = .typeSheet
                                }
                        }
                    }
                } else {
                    ZStack{
                        Text("Прикрепите договор")
                            .foregroundColor(Colors.textFieldOverlayGray)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                            .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(!selectedDocumentEmpty ? Colors.textFieldOverlayGray : Color.red))
                            .cornerRadius(18)
                            .padding(.top, -2)
                            .onTapGesture {
                                activeSheetOpenObject = .typeSheet
                            }
                            .onChange(of: selectedDocument) { newValue in
                                selectedDocumentEmpty = false
                            }
                        
                        HStack {
                            Spacer()
                            
                            Image("attach_file")
                                .padding(.horizontal, 16)
                                .onTapGesture {
                                    activeSheetOpenObject = .typeSheet
                                }
                        }
                    }
                }

                Text("Стоимость по договору")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)

                TextField("",text: $documentPrice, prompt: Text("Введите стоимость").foregroundColor(Colors.textFieldOverlayGray))
                    .autocapitalization(.none)
                    .foregroundColor(.black)
                    .disableAutocorrection(true)
                    .accentColor(Colors.orange)
                    .keyboardType(.numberPad)
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(!documentPriceEmpty ? Colors.textFieldOverlayGray : Color.red))
                    .cornerRadius(18)
                    .padding(.top, -2)
                    .onChange(of: documentPrice) { newValue in
                        documentPriceEmpty = false
                    }
                
                Spacer()
                
                Button(action: {
                    
                    IsUploadInProcess = true
                    
                    _ = selectedDocument
                    
                    print("Selected Start Date: \(selectedStartDate)")
                    print("Selected End Date: \(String(describing: selectedEndDate))")

                    // Проверяем обязательные поля
                    if startDate.isEmpty || startDate.count < 10 {
                        selectedStartDateEmpty = true
                        print("Start date is empty or less than 10 characters")
                    } else {
                        selectedStartDateEmpty = false
                    }
                    
                    if documentPrice.isEmpty || documentPrice.first == "0" {
                        documentPriceEmpty = true
                        print("Document price is empty")
                    } else {
                        documentPriceEmpty = false
                    }
                    
                    if selectedDocument == nil && generatedPDFURL == nil {
                        selectedDocumentEmpty = true
                        print("Selected document is nil")
                    } else {
                        selectedDocumentEmpty = false
                    }
                    
                    if selectedEndDate == nil {
                        selectedEndDateError = true
                    } else {
                        selectedEndDateError = false
                    }

                    // Если обязательные поля не пустые, продолжаем выполнение
                    if !selectedStartDateEmpty && !documentPriceEmpty && !selectedDocumentEmpty {
                        print("All required fields are filled, starting upload")
                        
                        let startDateTimestamp = Int64(selectedStartDate.timeIntervalSince1970 * 1000)
                        let endDateTimestamp: Int64? = selectedEndDate != nil ? Int64(selectedEndDate!.timeIntervalSince1970 * 1000) : nil

                        let openObjectRequest = OpenObjectRequest(
                            objectId: tappedObjectId,
                            startDate: startDateTimestamp,
                            endDate: endDateTimestamp, // Передаем nil, если дата окончания не выбрана
                            contractFinancialImpact: Double(documentPrice) ?? 0.0
                        )


                        if let documentURL = selectedDocument ?? generatedPDFURL {
                            uploadDocument(fileURL: documentURL, openObjectRequest: openObjectRequest) { result in
                                switch result {
                                case .success():
                                    print("Документ успешно загружен")
                                    needsRefresh = true
                                    DispatchQueue.main.async {
                                        if generatedPDFURL != nil {
                                            navigationPath.append(Destination.mainview)
                                            navigationPath.append(Destination.objectDetails)
                                        } else {
                                            navigationPath.removeLast(1)
                                        }
                                        IsUploadInProcess = false
                                        
                                        generatedPDFURL = nil
                                        selectedDocument = nil
                                    }
                                    
                                case .failure(let error):
                                    print("Ошибка при загрузке документа: \(error)")
                                    IsUploadInProcess = false
                                }
                            }
                        }
                    } else {
                        print("Не все обязательные поля заполнены") // Если какие-то обязательные поля не заполнены
                        IsUploadInProcess = false
                    }
                }, label: {
                    if IsUploadInProcess {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background((selectedDocument != nil && !documentPrice.isEmpty) ? Colors.orange : Colors.textFieldOverlayGray)
                            .cornerRadius(16)
                            .padding(.bottom, 16)
                    } else {
                        Text("Открыть объект")
                            .foregroundColor(Color.white)
                            .font(Fonts.Font_Headline2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(((selectedDocument != nil || generatedPDFURL != nil) && !documentPrice.isEmpty && !startDate.isEmpty && !documentPriceEmpty) ? Colors.orange : Colors.textFieldOverlayGray)
                            .cornerRadius(16)
                            .padding(.bottom, 16)
                    }
                })

            }
            .padding(.horizontal, 16)
        }
        .sheet(item: $activeSheetOpenObject) { sheet in
            switch sheet {
            case .typeSheet:
                OpenObjectBottomSheet(activeSheetOpenObject: $activeSheetOpenObject, navigationPath: $navigationPath)
            case .filePickerOpen:
                DocumentPicker(document: $selectedDocument)
                    .ignoresSafeArea()
            }
        }
        .onAppear{
            self.startDate = dateFormatter.string(from: Date())
            capturedMediaDoc = []
        }
        .onDisappear{
            print("onDisappear работает")
            selectedDocument = nil
            generatedPDFURL = nil
        }
    }
    
    func uploadDocument(fileURL: URL, openObjectRequest: OpenObjectRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        
        IsUploadInProcess = true
        
        let uploadURL = URL(string: "\(AppConfig.baseURL)objects/open")!
        
        // Создаем запрос
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        
        // Границы для multipart/form-data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = AccessTokenHolder.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Создаем тело запроса
        var body = Data()
        
        
        let jsonData = try? JSONEncoder().encode(openObjectRequest)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"openObjectRequest\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(jsonData!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Добавляем файл (документ) с именем 'file'
        let fileName = fileURL.lastPathComponent
        let mimeType = "application/octet-stream" // Можно определить тип файла для более точного значения
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        if let fileData = try? Data(contentsOf: fileURL) {
            body.append(fileData)
        }
        body.append("\r\n".data(using: .utf8)!)
        
        // Завершаем тело запроса
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Устанавливаем тело запроса
        request.httpBody = body
        
        // Выполняем запрос
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                IsUploadInProcess = false
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Ошибка от сервера: \(responseString)")
                    IsUploadInProcess = false
                }
                completion(.failure(NSError(domain: "", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Ошибка сервера"])))
                return
            }
            
            // Декодирование данных JSON в структуру ObjectResponse
            if let data = data {
                do {
                    let objectResponse = try JSONDecoder().decode(ObjectResponse.self, from: data)
                    // Здесь можно обновить данные или вызвать completion с успехом
                    completion(.success(()))
                    
                    // Обработайте objectResponse так, как вам необходимо
                    print("Object successfully updated: \(objectResponse)")
                } catch {
                    completion(.failure(error))
                    print("Ошибка декодирования JSON: \(error)")
                }
            }
            
            IsUploadInProcess = false
        }.resume()

    }
    
    private func formatDateInput(_ text: String) -> String {
        // Удаляем любые символы, кроме цифр
        let numbersOnly = text.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        var result = ""

        // Форматируем день
        if numbersOnly.count >= 2 {
            let day = String(numbersOnly.prefix(2))
            if let dayInt = Int(day), dayInt >= 1 && dayInt <= 31 {
                result.append(day)
            } else {
                result.append("31") // Некорректный день заменяем на 31
            }
        } else {
            result.append(numbersOnly)
            return result
        }

        // Форматируем месяц
        if numbersOnly.count >= 4 {
            result.append(".")
            let monthStart = numbersOnly.index(numbersOnly.startIndex, offsetBy: 2)
            let monthEnd = numbersOnly.index(monthStart, offsetBy: 2)
            let month = String(numbersOnly[monthStart..<monthEnd])
            if let monthInt = Int(month), monthInt >= 1 && monthInt <= 12 {
                result.append(month)
            } else {
                result.append("12") // Некорректный месяц заменяем на 12
            }
        } else if numbersOnly.count > 2 {
            result.append(".")
            let month = String(numbersOnly.suffix(from: numbersOnly.index(numbersOnly.startIndex, offsetBy: 2)))
            result.append(month)
            return result
        }

        // Форматируем год
        if numbersOnly.count > 4 {
            result.append(".")
            let year = String(numbersOnly.suffix(from: numbersOnly.index(numbersOnly.startIndex, offsetBy: 4)))
            result.append(year)
        }

        return result
    }

    // Форматтер для работы с датами в формате "dd.MM.yyyy"
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy" // Устанавливаем формат "дд.мм.гггг"
        return formatter
    }
    func getObjectAll(completion: @escaping (Bool) -> Void) {
        NetworkAccessor.shared.get("/objects/all") { (result: Result<[ObjectResponse], Error>, statusCode: Int?) in
            switch result {
            case .success(let data):
                dataResponseObjectAll = data
               
                // Проверяем статус-код
                if let statusCode = statusCode {
                    print("ебаный статус код \(statusCode)")
                    if statusCode == 403 {
                        print("Ошибка 403: Доступ запрещён.")
                    } else {
                        print("Получен статус-код: \(statusCode)")
                    }
                }
                print("getObjectAll Success")
            case .failure(let error):
                print("Error: \(error)")
               
                
            }
        }
    }
}


struct OpenObjectBottomSheet: View {
    
    @Binding var activeSheetOpenObject: OpenObjectSheetType?
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack {
            HStack{
                Text("Способ загрузки")
                    .font(Font.custom("Roboto", size: 20).weight(.semibold))
                    .padding(.top, 24)
                
                Spacer()
            }
            
            Button(action: {
                navigationPath.append(Destination.openObjectCamera)
                activeSheetOpenObject = nil
            }, label: {
                HStack{
                    Image("picture_as_pdf")
                    Text("Отснять")
                        .foregroundColor(Colors.orange)
                    Spacer()
                }
            })
            .padding(.top, 16)
            
            Button(action: {
                activeSheetOpenObject = nil // Закрываем текущий лист
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                       activeSheetOpenObject = .filePickerOpen // Открываем следующий лист
                   }
            }, label: {
                HStack{
                    Image("folder_open")
                    Text("Выбрать файл")
                        .foregroundColor(Colors.textFieldOverlayGray)
                    Spacer()
                }
            })
            Spacer()
            
        }
        .presentationDetents([.medium, .height(160)])
        .padding(.horizontal, 16)
    }
}

struct OpenObjectRequest : Codable {
    let objectId: String
    let startDate: Int64
    let endDate: Int64?
    let contractFinancialImpact: Double
}

//struct OpenObject_Previews: PreviewProvider {
//    
//    @State static var tappedObjectId: Int = 1 // Пример данных
//    @State static var navigationPath = NavigationPath() // Пример пути навигации
//    
//    static var previews: some View {
//        OpenObject(tappedObjectId: $tappedObjectId, navigationPath: $navigationPath)
//    }
//}
