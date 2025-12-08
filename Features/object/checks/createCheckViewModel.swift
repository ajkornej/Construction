//
//  createCheckViewModel.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 29.01.2025.
//

import Foundation

final class createCheckViewModel: ObservableObject {
    
    @Published var sheetNomenklatureTypeShown: Bool = false
    @Published var checkTypeSheetShow: Bool = false
    
    @Published var selectedOption = ""
    @Published var optionDescription = ""
    @Published var selectedOptionEmpty: Bool = false
    @Published var nomenclatures: [Nomenclatures] = []
    
    @Published var isButtonActive: Bool = false
    
    @Published var isLoading: Bool = false
    
    @Published var IsUploadInProcess: Bool = false
    
    let options = [
        ("DEL_CERT", "Акт сдачи"),
        ("ADD_AGREEMENT", "Доп. соглашение"),
        ("OTHER", "Другое")
    ]
    
    let type = [ "Доход", "Расход" ]
    
    @Published var documentName: String = ""
    @Published var documentNameCorrect: Bool = true
    
    @Published var documentPrice: String = ""
    @Published var documentPriceCorrect: Bool = true
    
    @Published var selectedDocument: URL?

    @Published var showingDocumentPicker = false
    @Published var generatedPDFURL: URL?
    
    @Published var selectedTypeCorrect: Bool = true
    @Published var nomenclatureStringCorrect: Bool = true
    @Published var tappedObjectId: String = ""
    @Published var isOutcome: Bool = false
    @Published var selectedType: String = ""
    @Published var nomenclatureString: String = ""
    @Published var checkTypeString: String = ""
    @Published var selectednomenclatureId: String = ""
    @Published var selectedDocumentCorrect: Bool = false
    
    @Published var fieldIsCorrect = false
    
    func fieldsIsCorrect() {
        selectedTypeCorrect = !checkTypeString.isEmpty
        nomenclatureStringCorrect = !nomenclatureString.isEmpty
        documentPriceCorrect = !documentPrice.isEmpty
        documentNameCorrect = !documentName.isEmpty

        fieldIsCorrect = selectedTypeCorrect && nomenclatureStringCorrect && documentPriceCorrect && documentNameCorrect
    }
    
    func uploadDocument(fileURL: URL?, checkRequest: PostCheck, objectId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        IsUploadInProcess = true

        guard !objectId.isEmpty else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "objectId не может быть пустым"])))
            return
        }
        
        // ✅ Генерация имени файла
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let currentDate = dateFormatter.string(from: Date())

        var generatedFileName = "Документ"
        
        if selectedOption == "DEL_CERT" {
            generatedFileName = "Акт сдачи от \(currentDate) к объекту №\(objectId)"
        } else if selectedOption == "ADD_AGREEMENT" {
            generatedFileName = "Доп. соглашение от \(currentDate) \(objectId)"
        }
        
        // Добавляем расширение, если есть файл
        if let fileURL = fileURL {
            let fileExtension = fileURL.pathExtension
            if !fileExtension.isEmpty {
                generatedFileName += ".\(fileExtension)"
            }
        }

        guard var components = URLComponents(string: "\(AppConfig.baseURL)tickets") else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Неверный URL"])))
            return
        }

        // Экранируем параметры
        components.queryItems = [
            URLQueryItem(name: "objectId", value: objectId),
            URLQueryItem(name: "fileWasRemoved", value: fileURL == nil ? "true" : "false")
        ]

        guard let uploadURL = components.url else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Неверный URL"])))
            return
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"

        print("@1 uploadURL\(uploadURL)")

        if let token = AccessTokenHolder.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // 🔹 Добавляем JSON-данные `PostCheck`
        do {
            let jsonData = try JSONEncoder().encode(checkRequest)

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"request\"; filename=\"request.json\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            body.append(jsonData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            IsUploadInProcess = false
            completion(.failure(error))
            return
        }

        // 🔹 Если файл **есть**, отправляем его. Если `fileURL == nil`, не добавляем файл.
        if let fileURL = fileURL, let fileData = try? Data(contentsOf: fileURL) {
            let mimeType = "application/octet-stream"

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(generatedFileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            self.IsUploadInProcess = false

            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                if (200...299).contains(statusCode) {
                    completion(.success(()))
                } else {
                    let responseString = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Неизвестная ошибка"
                    completion(.failure(NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: responseString])))
                }
            } else {
                completion(.failure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Некорректный HTTP-ответ"])))
            }
        }.resume()
    }

    func getAllNomenclatureId() {
        NetworkAccessor.shared.get("nomenclatures/all") { (result: Result<[Nomenclatures], Error>, statusCode: Int?) in
            switch result {
            case .success(let data):
                DispatchQueue.main.async { // ✅ Обновляем на главном потоке
                    self.nomenclatures = data
                }

                // Проверяем статус-код
                if let statusCode = statusCode {
                    print("Статус-код: \(statusCode)")
                    if statusCode == 403 {
                        print("Ошибка 403: Доступ запрещён.")
                    }
                }
                print("getObjectAll Success")

            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
}




struct PostCheck: Codable {
    let nomenclatureId: String
    let title: String
    let financialImpact: Double
    let isOutcome: Bool
}

struct Nomenclatures: Codable, Hashable {
    let nomenclatureId: String
    let title: String
}

struct CheckRequest: Codable {
    let title: String
    let ticketId: String
    let objectId: String
    let type: String
    let financialImpact: Double
    let nomenclatureId: String
    let isOutcome: Bool
}
