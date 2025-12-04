//
//  ChatViewModel.swift
//  Construction
//
//  Created by Корнеев Александр on 21.11.2024.
//

import Foundation
import Combine
import SocketIO
import ExyteChat

class ChatViewModel: ObservableObject {
    
    @Published var messages: [Message] = []  // Список сообщений
    @Published var isConnected: Bool = false  // Состояние подключения
    
    @Published var typingUsers: [String] = [] // Храним пользователей, которые печатают
    @Published var connectionStatus: String = ""
    
    @Published var typingTimer: Timer?
    
    @Published var currentSender: Sender?
    
    @Published var attachments: [ExyteChat.Attachment] = []
    
    @Published var sharedMaxAttachmentCount = 10
    
    @Published var isUploading: Bool = false
    
    @Published var isMessageLoaded: Bool = false
    
    var uploadProgressObserver: NSKeyValueObservation?

    @Published var isErrror: Bool = false
    
    
    private var currentPage: Int = 1
    private let limit: Int = 100
    private var allMessagesLoaded = false

    func loadOlderMessages(objectId: String, lastMessage: Message) async {
        guard !allMessagesLoaded else { return }

        currentPage += 1

        fetchChatMessages(objectId: objectId, page: currentPage, limit: 100) { newMessages in
            DispatchQueue.main.async {
                if newMessages.isEmpty {
                    self.allMessagesLoaded = true
                } else {
                    self.messages.insert(contentsOf: newMessages, at: 0)
                    
                    // Сортируем от новых к старым
                    self.messages.sort { $1.createdAt > $0.createdAt }
                }
            }
        }
    }
    
    @Published var uploadProgress: [FileUploadProgress] = []

    private var manager: SocketManager!
    private var socket: SocketIOClient!
    
    func setupSocket(objectId: String) {
        guard let token = AccessTokenHolder.shared.getAccessToken() else {
            print("Token not found in Keychain")
            return
        }
       
        let SOCKET_URL = "https://socket.example.ru"
        
        manager = SocketManager(socketURL: URL(string: SOCKET_URL)!, config: [
            .log(true),
            .compress,
            .forceWebsockets(true),
            .secure(true),
            .reconnects(true),  // Автоматическое переподключение
            .reconnectAttempts(3), // Ограничение на число попыток
            .reconnectWait(5),
            .connectParams(["Object-Id": objectId]),
            .extraHeaders(["Authorization": "Bearer \(token)"])
        ])

        socket = manager.socket(forNamespace: "/socket")
        
        print("Socket создаётся с Object-Id: \(objectId) и пространством /whateverNamespace")
       
        socket.on(clientEvent: .connect) { [weak self] data, ack in
            print("Socket connected")
            self?.isConnected = true
            self?.connectionStatus = "Подключен"
            self?.onConnected(objectId: objectId)
        }

        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("Socket disconnected")
            self?.isConnected = false
            self?.connectionStatus = "Отключен"
            self?.onDisconnected()
        }

        socket.on(clientEvent: .error) { data, ack in
            print("Socket connection error: \(data)")
        }

        socket.onAny { [weak self] event in
            self?.handleIncoming(event: event)
        }
        // Обработка события набора текста
        socket.on("TYPING") { [weak self] data, ack in
            guard let typingData = data.first as? [String: Any],
                  let userId = typingData["userId"] as? String,
                  let isTyping = typingData["isTyping"] as? Bool
            else { return }
        
            DispatchQueue.main.async {
                if isTyping {
                    if !self!.typingUsers.contains(userId) {
                        self!.typingUsers.append(userId)
                    }
                } else {
                    self!.typingUsers.removeAll { $0 == userId }
                }
            }
        }

        socket.on("NEW_MESSAGE") { [weak self] data, ack in
            guard let self = self, let rawData = data.first as? [String: Any] else {
                print("Invalid NEW_MESSAGE data")
                return
            }
            if let newMessage = self.parseIncomingMessage(rawData) {
                DispatchQueue.main.async {
                    // Проверяем, не существует ли уже сообщение с таким же ID
                    if !self.messages.contains(where: { $0.id == newMessage.id }) {
                        self.messages.append(newMessage)
                        // Сортируем от старых к новым
                        self.messages.sort { $1.createdAt > $0.createdAt }
                    }
                }
            }
        }
        socket.onAny { [weak self] event in
            self?.handleIncoming(event: event)
        }
        socket.onAny { event in
            print("Received event: \(event.event), data: \(event.items ?? [])")
        }
    }

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    private func onConnected(objectId: String) {
        print("Connected to socket with objectId: \(objectId)")
    }
    
    private func onDisconnected() {
        print("Disconnected from socket")
    }

    private func handleIncoming(event: SocketAnyEvent) {
        print("Incoming event: \(event)")
    }
    
    private let uploadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1 // Последовательная очередь
        return queue
    }()

    func uploadFile(
        fileURL: URL,
        progressUpdate: @escaping (Double) -> Void,
        completion: @escaping (String?) -> Void
    ) {
        
        let maxSize = 100 * 1024 * 1024
            guard let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                  fileSize < maxSize else {
                print("File too large")
                completion(nil)
                return
            }
        
        let uploadOperation = BlockOperation {
            let semaphore = DispatchSemaphore(value: 0)
            
            // AppConfig.baseURL
            
            let uploadURL = URL(string: "https://example.ru/files")!
            var request = URLRequest(url: uploadURL)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            if let token = AccessTokenHolder.shared.getAccessToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            var data = Data()
            let originalFileName = fileURL.deletingPathExtension().lastPathComponent
            let fileExtension = fileURL.pathExtension
            let uniqueSuffix = UUID().uuidString
            let uniqueFileName = "\(originalFileName)_\(uniqueSuffix).\(fileExtension)"
            
            // Определение MIME-типа
            let mimeType: String
            switch fileExtension.lowercased() {
            case "jpg", "jpeg": mimeType = "image/jpeg"
            case "png": mimeType = "image/png"
            case "mov": mimeType = "video/quicktime"
            case "mp4": mimeType = "video/mp4"
            default: mimeType = "application/octet-stream"
            }
            // Формирование тела запроса
            do {
                data.append("--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(uniqueFileName)\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                data.append(try Data(contentsOf: fileURL))
                data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            } catch {
                print("Error reading file: \(error)")
                DispatchQueue.main.async { completion(nil) }
                semaphore.signal()
                return
            }
            
            var resultFilename: String?
            var uploadProgressObserver: NSKeyValueObservation?
            
            let task = URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
                defer { semaphore.signal() }
                
                if let error = error {
                    print("Upload error: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Server error: \(response.debugDescription)")
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                
                guard let responseData = responseData else {
                    print("Server returned no data")
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                       let filename = json["filename"] as? String {
                        resultFilename = filename
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                }
                
                DispatchQueue.main.async {
                    completion(resultFilename)
                }
            }
            
            // Наблюдение за прогрессом
            uploadProgressObserver = task.observe(\.countOfBytesSent) { task, _ in
                let progress = Double(task.countOfBytesSent) / Double(task.countOfBytesExpectedToSend)
                DispatchQueue.main.async {
                    progressUpdate(progress)
                }
            }
            
            task.resume()
            semaphore.wait()
            uploadProgressObserver?.invalidate()
        }
        
        uploadQueue.addOperation(uploadOperation)
    }

    func sendMessage(text: String, fileURLs: [URL]) {
        guard !text.isEmpty || !fileURLs.isEmpty else {
            print("Nothing to send")
            return
        }
        
        // Инициализация прогресса для файлов
        DispatchQueue.main.async {
            for fileURL in fileURLs {
                let progress = FileUploadProgress(fileURL: fileURL, progress: 0)
                self.uploadProgress.append(progress)
            }
        }
        
        let dispatchGroup = DispatchGroup()
        var filenames: [String] = []
        
        if !fileURLs.isEmpty {
            for fileURL in fileURLs {
                dispatchGroup.enter()
                uploadFile(fileURL: fileURL, progressUpdate: { progress in
                    DispatchQueue.main.async {
                        if let uploadIndex = self.uploadProgress.firstIndex(where: { $0.fileURL == fileURL }) {
                            self.uploadProgress[uploadIndex].progress = progress
                        }
                    }
                }) { filename in
                    DispatchQueue.main.async {
                        if let filename = filename {
                            filenames.append(filename)
                        }
                        if let uploadIndex = self.uploadProgress.firstIndex(where: { $0.fileURL == fileURL }) {
                            self.uploadProgress[uploadIndex].isCompleted = true
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        // Когда все загрузки завершены
        dispatchGroup.notify(queue: .main) {
            print("All files uploaded. Proceeding to send the message.")
            
            // Формируем сообщение и отправляем его
            let messageId = UUID().uuidString
            let createdDate = Date()
            let sender = ExyteChat.User(id: currentUserId ?? "1", name: "You", avatarURL: nil, isCurrentUser: true)
            
            var messageData: [String: Any] = [
                "messageId": messageId,
                "createdAt": createdDate.timeIntervalSince1970 * 1000
            ]
            
            if !text.isEmpty {
                messageData["text"] = text
            }
            
            if !filenames.isEmpty {
                messageData["filenames"] = filenames
            }
            
            self.socket.emit("CHAT_MESSAGE", messageData)
            print("Message sent: \(messageData)")
            
            // Добавляем сообщение в локальный UI
            let attachments: [ExyteChat.Attachment] = fileURLs.map { fileURL in
                let fileExtension = fileURL.pathExtension.lowercased()
                let attachmentType: ExyteChat.AttachmentType
                
                if ["jpg", "jpeg", "png", "gif"].contains(fileExtension) {
                    attachmentType = .image
                } else if ["mp4", "mov", "avi" ,"MOV"].contains(fileExtension) {
                    attachmentType = .video
                } else {
                    let file = ExyteChat.File(
                        filename: fileURL.lastPathComponent,
                        contentType: "application/octet-stream",
                        displayTitle: fileURL.lastPathComponent,
                        downloadUrl: fileURL.absoluteString,
                        extension: fileExtension,
                        fileSize: 0
                    )
                    attachmentType = .file(file)
                }
                
                return ExyteChat.Attachment(
                    id: UUID().uuidString,
                    thumbnail: fileURL,
                    full: fileURL,
                    type: attachmentType
                )
            }
            
            _ = ExyteChat.Message(
                id: messageId,
                user: sender,
                status: .sent,
                createdAt: createdDate,
                text: text,
                attachments: attachments,
                recording: nil,
                replyMessage: nil,
                params: ["role": "User"]
            )
            
//            self.messages.append(message)
            
            // Очищаем состояние загрузки
            self.uploadProgress.removeAll()
            self.attachments.removeAll() // Удаляем только после завершения
        }
    }

    func fetchChatMessages(objectId: String, page: Int, limit: Int = 100, completion: @escaping ([Message]) -> Void) {
        let baseURL = "https://example.ru/chat/messages"
        
        
//        let encodedObjectId = objectId.utf8Encoded
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "objectId", value: "\(objectId)"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
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
                self.isErrror = true
            }
        }
        
        task.resume()
        
        
    }
    
    private func parseIncomingMessage(_ data: [String: Any]) -> Message? {
        guard
            let rawData = data["data"] as? [String: Any],
            let messageId = rawData["messageId"] as? String,
            let createdAtTimestamp = rawData["time"] as? Double,
            let senderData = rawData["sender"] as? [String: Any],
            let userId = senderData["userId"] as? String,
            let name = senderData["name"] as? String
        else {
            print("Invalid message format: \(data)")
            return nil
        }

        let sender = ExyteChat.User (
            id: userId,
            name: name,
            avatarURL: URL(string: senderData["imageUrl"] as? String ?? ""),
            isCurrentUser: userId == currentUserId
        )

        let createdAt = Date(timeIntervalSince1970: createdAtTimestamp / 1000)
        let text = rawData["text"] as? String ?? ""

        // Обработка вложений, если они есть
        let attachmentsData = rawData["attachments"] as? [String: Any] ?? [:]
        let mediaAttachments = (attachmentsData["medias"] as? [[String: Any]]) ?? []
        let fileAttachments = (attachmentsData["files"] as? [[String: Any]]) ?? []
        
        for attachment in attachments {
            print("Attachment ID: \(attachment.id), Type: \(attachment.type)")
        }


        let attachments = mediaAttachments.compactMap { mediaDict -> ExyteChat.Attachment? in
            guard let fullUrlString = mediaDict["originalUrl"] as? String,
                  let fullUrl = URL(string: fullUrlString) else {
                print("Invalid URL in mediaDict: \(mediaDict)")
                return nil
            }

            let thumbnailUrl = (mediaDict["thumbnailUrl"] as? String).flatMap { URL(string: $0) } ?? fullUrl

            // Конвертация значений image и video в Bool
            let isVideo = (mediaDict["video"] as? Int == 1)
            let isImage = (mediaDict["image"] as? Int == 1)

            // Определение типа вложения
            var attachmentType: ExyteChat.AttachmentType
            if isVideo {
                attachmentType = .video
            } else if isImage {
                attachmentType = .image
            } else {
                print("Invalid media type in mediaDict: \(mediaDict)")
                return nil
            }

            return ExyteChat.Attachment(
                id: mediaDict["id"] as? String ?? UUID().uuidString,
                thumbnail: thumbnailUrl,
                full: fullUrl,
                type: attachmentType
            )
        } + fileAttachments.compactMap { fileDict -> ExyteChat.Attachment? in
            guard let fileUrlString = fileDict["downloadUrl"] as? String,
                  let fileUrl = URL(string: fileUrlString),
                  let filename = fileDict["filename"] as? String else {
                print("Invalid URL in fileDict: \(fileDict)")
                return nil
            }

            // Обработка файла как вложения
            let file = ExyteChat.File(
                filename: filename,
                contentType: fileDict["contentType"] as? String ?? "application/octet-stream",
                displayTitle: fileDict["displayTitle"] as? String ?? filename,
                downloadUrl: fileUrlString,
                extension: fileUrl.pathExtension,
                fileSize: fileDict["fileSize"] as? Int ?? 0
            )

            return ExyteChat.Attachment(
                id: UUID().uuidString,
                thumbnail: fileUrl, // Файлы могут не иметь миниатюры
                full: fileUrl,
                type: .file(file)
            )
        }
        // Получаем роль из senderData
            let role = senderData["jobTitle"] as? String ?? ""

            return ExyteChat.Message(
                id: messageId,
                user: sender,
                status: .sent,
                createdAt: createdAt,
                text: text,
                attachments: attachments,
                recording: nil,
                replyMessage: nil,
                params: ["role": role] // Добавляем роль в params
            )
    }
    
    func addAttachments(_ newAttachments: [ExyteChat.Attachment]) {
            let currentCount = attachments.count
            let remainingCount = sharedMaxAttachmentCount - currentCount
            if remainingCount > 0 {
                let allowedAttachments = Array(newAttachments.prefix(remainingCount))
                attachments.append(contentsOf: allowedAttachments)
            } else {
                print("❌ Превышен общий лимит в \(sharedMaxAttachmentCount) вложений")
            }
        }
    
    func sendTypingStatus(isTyping: Bool) {
        
        let typingData: [String: Any] = [
            "userId": UUID().uuidString,
            "isTyping": isTyping
        ]
        
        socket.emit("TYPING", typingData)
    }
}

extension ChatMessage {
    func toChatMessage() -> ExyteChat.Message {
        let createdDate = Date(timeIntervalSince1970: TimeInterval(time) / 1000)
        
        // Используем метод toChatAttachments для преобразования attachments
        let chatAttachments = attachments.toChatAttachments()
        
        return ExyteChat.Message(
            id: messageId,
            user: sender.toChatUser(), 
            status: nil,
            createdAt: createdDate,
            text: text ?? "",
            attachments: chatAttachments,
            recording: nil,
            replyMessage: nil,
            params: ["role": sender.jobTitle]
        )
    }
}

extension Sender {
    func toChatUser() -> ExyteChat.User {
        ExyteChat.User(
            id: userId,
            name: name,
            avatarURL: URL(string: imageUrl ?? ""),
            isCurrentUser: (userId == currentUserId)
        )
    }
}

extension Attachments {
    func toChatMediaAttachments() -> [ExyteChat.Attachment] {
        medias.compactMap { $0.toChatAttachment() }
    }

    func toChatFileAttachments() -> [ExyteChat.Attachment] {
        files.compactMap { $0.toChatAttachment() }
    }

    func toChatAttachments() -> [ExyteChat.Attachment] {
        // Объединяем медиа и файлы только при необходимости
        toChatMediaAttachments() + toChatFileAttachments()
    }
}

extension Mediaa {
    func toChatAttachment() -> ExyteChat.Attachment? {
        guard let fullUrl = URL(string: self.originalUrl) else {
            print("Invalid URL for media full: \(self.originalUrl)")
            return nil
        }
        
        let thumbnailUrl = self.thumbnailUrl.flatMap { URL(string: $0) } ?? fullUrl
        
        let attachmentType: ExyteChat.AttachmentType
        
        if self.video {
            attachmentType = .video
        } else if self.image {
            attachmentType = .image
        } else {
            // Добавляем обработку файлов
            let mappedFile = ExyteChat.File(
                filename: self.id,
                contentType: "application/octet-stream",
                displayTitle: "Attachment",
                downloadUrl: self.originalUrl,
                extension: fullUrl.pathExtension,
                fileSize: 0
            )
            attachmentType = .file(mappedFile)
        }
        
        return ExyteChat.Attachment(
            id: self.id,
            thumbnail: thumbnailUrl,
            full: fullUrl,
            type: attachmentType
        )
    }
}

extension Array where Element == ExyteChat.Attachment {
    var mediaCount: Int {
        return self.count
    }
}

extension File {
    func toChatAttachment() -> ExyteChat.Attachment? {
        guard let fileUrl = URL(string: self.downloadUrl) else {
            print("Invalid URL for file: \(self.downloadUrl)")
            return nil
        }
        let mappedFile = ExyteChat.File(
            filename: filename,
            contentType: contentType,
            displayTitle: displayTitle,
            downloadUrl: downloadUrl,
            extension: self.extension,
            fileSize: fileSize
        )

        return ExyteChat.Attachment(
            id: self.filename,
            thumbnail: fileUrl,
            full: fileUrl,
            type: .file(mappedFile)
        )
    }
}

extension URL {
    /// Конвертирует `URL` в `ExyteChat.Attachment`
    func toChatAttachment(fileSize: Int) -> ExyteChat.Attachment? {
        let file = ExyteChat.File(
            filename: self.lastPathComponent,
            contentType: "application/octet-stream", // Вы можете использовать MIME-тип, если доступен
            displayTitle: self.lastPathComponent,
            downloadUrl: self.absoluteString,
            extension: self.pathExtension,
            fileSize: fileSize // Передаем размер файла
        )
        return ExyteChat.Attachment(
            id: UUID().uuidString, // Генерируем уникальный идентификатор
            thumbnail: self, // Используем URL для thumbnail
            full: self, // URL файла
            type: .file(file) // Указываем тип вложения
        )
    }
}

private var currentUserId: String? {
    loadAuthenticationResponse()?.user.userId
}

func loadAuthenticationResponse() -> AuthenticationResponse? {
    if let authData = UserDefaults.standard.data(forKey: "authResponse") {
        do {
            let decoder = JSONDecoder()
            let authResponse = try decoder.decode(AuthenticationResponse.self, from: authData)
            return authResponse
        } catch {
            print("Ошибка при загрузке AuthenticationResponse: \(error.localizedDescription)")
        }
    }
    return nil
}

struct ChatMessageResponse: Codable {
    let totalPages: Int?
    let totalElements: Int?
    let size: Int?
    let content: [ChatMessage]
    let number: Int?
    let sort: Sort?
    let numberOfElements: Int?
    let pageable: Pageable?
    let first: Bool?
    let last: Bool?
    let empty: Bool?
}

struct ChatMessage: Identifiable, Codable, Hashable, Equatable {
    var id: String { messageId }
    let messageId: String
    let sender: Sender
    let time: Int
    let text: String?
    let attachments: Attachments
}

struct Sender: Codable, Hashable, Equatable {
    var userId: String
    let name: String
    let surname: String
    let isEmployee: Bool?
    let patronymic: String
    let imageUrl: String?
    let jobTitle: String?

}

struct Attachments: Codable, Hashable, Equatable {
    let medias: [Mediaa]
    let files: [File]
}

struct File: Codable, Hashable, Equatable {
    let filename: String
    let contentType: String
    let displayTitle: String
    let downloadUrl: String
    let `extension`: String
    let fileSize: Int
}

struct Mediaa: Codable, Identifiable, Equatable, Hashable {
    var id: String { originalUrl }
    let originalUrl: String
    var thumbnailUrl: String?
    let contentType: String
    let displayTitle: String
    let video: Bool
    let image: Bool
}

struct FileUploadProgress: Identifiable {
    let id = UUID()
    let fileURL: URL
    var progress: Double // Значение от 0.0 до 1.0
    var isCompleted: Bool = false
}

extension String {
    var win1251Encoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved, using: .win1251)
    }
}

extension String {
    var utf8Encoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}

extension String.Encoding {
    static let win1251 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.windowsCyrillic.rawValue)))
}

extension CharacterSet {
    static let rfc3986Unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~=&+")
}

extension String {
    func addingPercentEncoding(withAllowedCharacters characterSet: CharacterSet, using encoding: String.Encoding) -> String {
        let stringData = self.data(using: encoding, allowLossyConversion: true) ?? Data()
        let percentEscaped = stringData.map { byte -> String in
            if characterSet.contains(UnicodeScalar(byte)) {
                return String(UnicodeScalar(byte))
            } else if byte == UInt8(ascii: " ") {
                return "+"
            } else {
                return String(format: "%%%02X", byte)
            }
        }.joined()
        return percentEscaped
    }
}
