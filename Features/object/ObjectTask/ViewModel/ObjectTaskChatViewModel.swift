//
//  ObjectTaskChatViewModel.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 06.03.2025.
//

import Foundation
import ExyteChat

class ObjectTaskChatViewModel: ObservableObject {
    
    @Published var messages: [Message] = []
    @Published var attachments: [ExyteChat.Attachment] = []
    @Published var sharedMaxAttachmentCount = 10
    
    func getTaskChat(taskId: String, page: Int, limit: Int = 100, completion: @escaping ([Message]) -> Void) {
    
        let baseURL = "\(AppConfig.baseURL)/tasks/\(taskId)/comments"
        
        var urlComponents = URLComponents(string: baseURL)!
       
        guard let url = urlComponents.url else {
            print("Invalid URL")
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(AccessTokenHolder.shared.getAccessToken() ?? "")", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching messages: \(error)")
                completion([]) // Возвращаем пустой массив в случае ошибки
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Server returned error")
                completion([]) // Возвращаем пустой массив при ошибке сервера
                return
            }

            guard let data = data else {
                print("No data returned from server")
                completion([]) // Возвращаем пустой массив, если нет данных
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase // Если сервер использует snake_case
                let response = try decoder.decode(ChatMessageResponse.self, from: data)
                
                // Конвертируем ChatMessage в ExyteChat.Message
                let exyteChatMessages = response.content.map { $0.toChatMessage() }
                completion(exyteChatMessages)
            } catch {
                print("Decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON: \(jsonString)")
                }
                completion([]) // Возвращаем пустой массив при ошибке декодирования
            }
        }
        
        task.resume()
    }
    
    func postTaskChat(taskId: String, text: String, fileURLs: [URL]) {
        
    }
}
