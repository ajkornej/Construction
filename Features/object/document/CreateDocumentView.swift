//
//  CreateDocumentView.swift
//  stroymir
//
//  Created by Корнеев Александр on 10.08.2024.
//

import SwiftUI
import PDFKit
import Combine
import UIKit

struct CreateDocumentView: View {
    
    @Binding var navigationPath: NavigationPath
    @Binding var tappedObjectId: String
    @State private var showingDocumentPicker = false
    
    @State private var selectedDocument: URL?
    @State var selectedDocumentEmpty:  Bool = false
   
    @Binding var generatedPDFURL: URL? // Передаем сюда PDF
    
    @State var documentName: String = ""
    @State var documentNameEmpty: Bool = false
    
    @State var documentPrice: String = ""
    @State var documentPriceEmpty: Bool = false
    
    @State private var selectedOption = ""
    @State var selectedOptionEmpty: Bool = false
    
    @State private var optionDescription = ""
    
    @State private var isDropdownExpanded = false
    @State var loadingDoc: Bool = false
    
    @State var IsUploadInProcess: Bool = false
    
    @State var sheetShown: Bool = false
    
    @State var startDate: String = ""
    @State var endDate: String = ""
    @State var startDateError: Bool = false
    @State var endDateEmpty: Bool = false
    
    @State private var selectedStartDate = Date()
    @State private var selectedStartDateEmpty: Bool = false
    
    @State private var selectedEndDate: Date? = nil // Опциональная дата
    
    @State var selectedEndDateError: Bool = false
    
    @State private var isDatePickerPresented = false
    
    @State private var isEndDatePickerPresented = false
    
    let options = [
        ("DEL_CERT", "Акт выполненных работ"),
        ("CLOSING_CERT", "Акт сдачи-приемки"),
        ("TERMINATED_CERT", "Акт расторжения"),
        ("EXTENSION_CERT", "Акт продления"),
        ("ADD_AGREEMENT", "Акт доп. работ")
    ]
    
    let paymentType = ["Наличные", "Безналичный расчёт"] // Убрали лишние скобки

    // Состояния
    @State private var selectedPaymentType: String = ""
    @State private var isPaymentTypeSheetShown = false // Переименовали для ясности
    @State var  selectedPaymentTypeEmpty: Bool = false
    
    var body: some View {
        VStack{
            ScrollView{
                Text("Тип документа")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)
                
                Button(action: {
                    sheetShown = true
                }) {
                    HStack {
                        Text(selectedOption.isEmpty ? "Выберите тип документа" : optionDescription)
                            .foregroundColor(selectedOption.isEmpty ? Colors.textFieldOverlayGray : .black)
                        Spacer()
                        Image(systemName: sheetShown ? "chevron.up" : "chevron.down")
                            .foregroundColor(Colors.textFieldOverlayGray)
                    }
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(!selectedOptionEmpty ? Colors.textFieldOverlayGray: Color.red))
                    .cornerRadius(18)
                }
                .onChange(of: selectedOption) { newValue in
                    selectedOptionEmpty = false
                }
                
                Text("Номер")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)
                
                TextField("",text: $documentName, prompt: Text("Введите название").foregroundColor(Colors.textFieldOverlayGray))
                    .autocapitalization(.none)
                    .foregroundColor(.black)
                    .disableAutocorrection(true)
                    .textContentType(.emailAddress)
                    .accentColor(Colors.orange)
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(!documentNameEmpty ? Colors.textFieldOverlayGray : Color.red))
                    .cornerRadius(18)
                    .padding(.top, -2)
                    .onChange(of: documentName) { newValue in
                        documentNameEmpty = false
                    }
                
    
                Text("Дата создания")
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
                
                if selectedOption == "DEL_CERT" {
                
                    Text("Стоимость по акту выполнения работ")
                        .font(Fonts.Font_Callout)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 12)
                    
                    TextField("",text: $documentPrice, prompt: Text("Введите сумму").foregroundColor(Colors.textFieldOverlayGray))
                        .autocapitalization(.none)
                        .foregroundColor(.black)
                        .disableAutocorrection(true)
                        .keyboardType(.numberPad)
                        .accentColor(Colors.orange)
                        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                        .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(!documentPriceEmpty ? Colors.textFieldOverlayGray : Color.red))
                        .cornerRadius(18)
                        .padding(.top, -2)
                        .onChange(of: documentPrice) { newValue in
                            documentPriceEmpty = false
                        }
                    
                    Text("Способ оплаты")
                        .font(Fonts.Font_Callout)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 12)
                    
                    Button(action: {
                        isPaymentTypeSheetShown.toggle() // Используем toggle() для удобства
                    }) {
                        HStack {
                            Text(selectedPaymentType.isEmpty ? "Выберите тип оплаты" : selectedPaymentType)
                                .foregroundColor(selectedPaymentType.isEmpty ? Colors.textFieldOverlayGray : .black)
                            Spacer()
                            Image(systemName: isPaymentTypeSheetShown ? "chevron.up" : "chevron.down")
                                .foregroundColor(Colors.textFieldOverlayGray)
                        }
                        .padding(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .inset(by: 1)
                                .stroke(selectedPaymentTypeEmpty ? Color.red : Colors.textFieldOverlayGray)
                        )
                        .cornerRadius(18)
                    }
                    .onChange(of: selectedPaymentType) { newValue in
                        selectedPaymentTypeEmpty = false
                    }
                    .sheet(isPresented: $isPaymentTypeSheetShown) {
                        VStack(/*spacing: 0*/) {
                            // Заголовок
                            HStack {
                                Text("Выберите тип оплаты")
                                    .font(Font.custom("Roboto", size: 20).weight(.semibold))
                                    .padding(.top, 24)
                                Spacer()
                            }
                            .padding(.bottom, 16)
                            
                            // Список вариантов
                            VStack(spacing: 16) {
                                ForEach(paymentType, id: \.self) { type in // Исправили идентификатор
                                    Button(action: {
                                        selectedPaymentType = type
                                        isPaymentTypeSheetShown = false
                                    }) {
                                        HStack {
                                            Text(type)
                                                .font(Fonts.Font_Headline2)
                                                .foregroundColor(Color.black)
                                            Spacer()
                                        }
                                        .contentShape(Rectangle()) // Увеличили область нажатия
                                    }
                                }
                            }
                            
                            Spacer()
                            
                        }
                        .padding(.horizontal, 16)
                        .presentationDetents([.height(200)]) // Оптимизировали высоту
                    }
                    
                }
                
                if selectedOption == "CLOSING_CERT" {
                    
                    Text("Дата закрытия")
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
                }
                    
                
                   
                Text("Файл")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)
                
                ZStack{
        
                    if let document = selectedDocument {
                        Text("Выбранный документ: \(document.lastPathComponent)")
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                            .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(Colors.textFieldOverlayGray))
                            .cornerRadius(18)
                            .padding(.top, -2)
                            .onTapGesture {
                                showingDocumentPicker = true
                            }
                    } else if let generatedPDF = generatedPDFURL {
                        Text("\(generatedPDF.lastPathComponent)")
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                            .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(Colors.textFieldOverlayGray))
                            .cornerRadius(18)
                            .padding(.top, -2)
                            .onTapGesture {
                                showingDocumentPicker = true
                            }
                    } else {
                        Text("Выберете файл")
                            .foregroundColor(Colors.textFieldOverlayGray)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                            .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(!selectedDocumentEmpty ? Colors.textFieldOverlayGray : Color.red))
                            .cornerRadius(18)
                            .padding(.top, -2)
                            .onTapGesture {
                                showingDocumentPicker = true
                            }
                            .onChange(of: selectedDocument) { newValue in
                                selectedDocumentEmpty = false
                            }
                    }
                    HStack{
                        Spacer()
                        
                        Image("attach_file")
                            .padding(.horizontal, 16)
                    }
                    .onTapGesture {
                        showingDocumentPicker = true
                    }
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(document: $selectedDocument)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $sheetShown) {
                VStack {
                    HStack{
                        Text("Выберите тип документа")
                            .font(Font.custom("Roboto", size: 20).weight(.semibold))
                            .padding(.top, 24)
                        
                        Spacer()
                    }
                    ForEach(options, id: \.0) { option, text in
                        Button(action: {
                            withAnimation {
                                selectedOption = option
                                sheetShown = false
                                optionDescription = text
//                                setDocumentName()
                            }
                        }) {
                            Text(text)
                                .font(Fonts.Font_Headline2)
                                .foregroundColor(Color.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.top, 16)
                    Spacer()
                }
                .presentationDetents([.medium, .height(420)])
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, 16)
            .navigationTitle("Новый документ")
        }
        .onDisappear {
            generatedPDFURL = nil
        }
        
        Button(action: {
            print(" selectedDocumentEmpty\(selectedDocumentEmpty), selectedOptionEmpty \(selectedOptionEmpty),documentNameEmpty  \(documentNameEmpty),documentPriceEmpty \(documentPriceEmpty)  ")
            
            if IsUploadInProcess == false {
                
                if selectedDocument == nil && generatedPDFURL == nil {
                    selectedDocumentEmpty = true
                }
                if selectedOption.isEmpty {
                    selectedOptionEmpty = true
                }
                if documentName.isEmpty {
                    documentNameEmpty = true
                }
                if selectedPaymentType.isEmpty && selectedOption == "DEL_CERT" {
                    selectedPaymentTypeEmpty = true
                }
                
                // Проверяем поле стоимости только если выбран тип документа не "OTHER"
                if documentPrice.isEmpty && selectedOption == "DEL_CERT" {
                    documentPriceEmpty = true
                } else {
                    documentPriceEmpty = false
                }
                
                // Продолжаем процесс загрузки только если все обязательные поля заполнены
                let documentURL = selectedDocument ?? generatedPDFURL
                if let documentURL = documentURL, !documentName.isEmpty, !documentPriceEmpty, !selectedOption.isEmpty {
                    let documentRequest = DocumentRequest(
                        title: documentName,
                        objectId: tappedObjectId,
                        type: selectedOption,
                        financialImpact: Double(documentPrice) ?? 0.0,
                        payedByCash: selectedPaymentType == "Наличные", 
                        number: documentName
                    )
                    
                    print(documentRequest)
                    
                    uploadDocument(fileURL: documentURL, documentRequest: documentRequest) { result in
                        switch result {
                        case .success():
                            print("Документ успешно загружен")
                            DispatchQueue.main.async {
                                if generatedPDFURL != nil {
                                    navigationPath.removeLast(3)
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
            }
        }, label: {
            if IsUploadInProcess {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background((selectedDocument != nil && !documentPriceEmpty) ? Colors.orange : Colors.textFieldOverlayGray)
                    .cornerRadius(16)
                    .padding(.bottom, 8)
            } else {
                HStack {
                    Text("Загрузить документ")
                        .foregroundColor(Color.white)
                        .font(Fonts.Font_Headline2)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background((!documentName.isEmpty && !documentPriceEmpty && (selectedDocument != nil || generatedPDFURL != nil) && !selectedOption.isEmpty) ? Colors.orange : Colors.textFieldOverlayGray)
                .cornerRadius(16)
                .padding(.bottom, 8)
            }
        })
        .padding(.horizontal, 16)
        
        Spacer()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy" // Устанавливаем формат "дд.мм.гггг"
        return formatter
    }
    
    // Автоматически устанавливает название документа с текущей датой для определённых опций
//    func setDocumentName() {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "dd.MM.yyyy"
//        let currentDate = dateFormatter.string(from: Date())
//        
//        if selectedOption == "DEL_CERT" {
//            documentName = "Акт выполненных работ от \(currentDate) к объекту №\(tappedObjectId)"
//        } else if selectedOption == "CLOSING_CERT" {
//            documentName = "Акт сдачи-приемки от \(currentDate) к объекту №\(tappedObjectId)"
//            
//        } else if selectedOption == "TERMINATED_CERT" {
//            documentName = "Акт расторжения от \(currentDate) к объекту №\(tappedObjectId)"
//            
//        } else if selectedOption == "EXTENSION_CERT" {
//            documentName = "Акт продления от \(currentDate) к объекту №\(tappedObjectId)"
//            
//        } else if selectedOption == "ADD_AGREEMENT" {
//            documentName = "Акт доп. работ от \(currentDate) к объекту №\(tappedObjectId)"
//        }
//    }
    
    func uploadDocument(fileURL: URL, documentRequest: DocumentRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        
        IsUploadInProcess = true
       
        let uploadURL = URL(string: "\(AppConfig.baseURL)documents")!
        
        // Создаем запрос
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        
        // Границы для multipart/form-data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = AccessTokenHolder.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Создаем тело запроса
        var body = Data()
        
        // Добавляем JSON данные для DocumentRequest с именем 'documentRequest'
        let jsonData = try? JSONEncoder().encode(documentRequest)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"documentRequest\"\r\n".data(using: .utf8)!)
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
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Ошибка от сервера: \(responseString)")
                }
                completion(.failure(NSError(domain: "", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Ошибка сервера"])))
                return
            }
            IsUploadInProcess = false
            completion(.success(()))
        }.resume()
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var document: URL?

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            self.parent.document = urls.first
        }
    }
}
