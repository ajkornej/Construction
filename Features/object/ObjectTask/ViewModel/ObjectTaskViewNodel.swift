//
//  ObjectTaskViewModel.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 11.02.2025.
//

import Foundation

class ObjectTaskViewModel: ObservableObject {
    
    @Published var isProblem: Bool = false
    @Published var tisckets: TaskModel?
    
    func createDateTime(timestamp: String) -> String {
        
        var endDate = ""
        
        if let unixTimeMillis = Double(timestamp) {
            // Делим значение временной метки на 1000, чтобы получить секунды
            let unixTimeSeconds = unixTimeMillis / 1000
            let date = Date(timeIntervalSince1970: unixTimeSeconds)
            let dateFormatter = DateFormatter()
            let timezone = TimeZone.current.abbreviation() ?? "CET"
            dateFormatter.timeZone = TimeZone(abbreviation: timezone)
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateFormat = "d MMM yyyy'г.'"
            let formattedDate = dateFormatter.string(from: date)
            endDate = formattedDate
        }

        return endDate
    }

    func getTasks(for taskId: String) {
        let baseURL = AppConfig.baseURL
        let endpoint = "tasks"

        var components = URLComponents(string: baseURL + endpoint)!
        components.queryItems = [
            URLQueryItem(name: "taskId", value: taskId),
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: "100")
        ]

        guard let url = components.url else {
            print("❌ Не удалось сформировать URL")
            return
        }

        print("📤 Отправляем запрос на URL: \(url.absoluteString)")

        NetworkAccessor.shared.get(url.absoluteString) { (result: Result<Data, Error>, statusCode: Int?) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📥 Получен RAW JSON:\n\(jsonString)")
                    } else {
                        print("⚠️ Не удалось декодировать данные в строку")
                    }
                case .failure(let error):
                    print("❌ Ошибка запроса: \(error)")
                }
            }
        }
    }

    
    
    func taskAction(taskId: String) {
        let endpoint = "tasks/\(taskId)/action"
        
        // Если нужно отправлять тело запроса (например, для изменения статуса)
        let requestBody = ["status": "completed"] // Пример тела запроса
        
        NetworkAccessor.shared.put(endpoint, body: requestBody) { (result: Result<TaskModel, Error>, statusCode: Int?) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    print("Success: \(data)")
                    self.tisckets = data // Обновляем tisckets
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
}


struct TaskModel: Codable {
    let taskId: UUID
    let title: String
    let creator: User
    let deadline: Int
    let description: String
    let progress: String
    let objectIds: [String]
    let executors: [Executor]
    let isProblem: Bool
    let medias: [Media]
    let buttonText: String?
}

struct User: Codable {
    let userId: UUID
    let name: String
    let surname: String
    let isEmployee: Bool
    let patronymic: String
    let imageUrl: String?
    let jobTitle: String
}

struct Executor: Codable {
    let executor: User
    let status: String
    let statusColor: StatusColor
    let date: Int
    let canBeAccepted: Bool
}

struct StatusColor: Codable {
    let hex: String
}
