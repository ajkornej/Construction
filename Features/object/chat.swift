//
//
/////
/////
/////
/////
//
//
//import SwiftUI
//import SocketIO
//import Combine
//import AVKit
//import Kingfisher
//
//
//struct ChatView: View {
//    
//    @Binding var tappedObjectId: Int
//    
//    @Binding var navigationPath: NavigationPath
//    
//    @ObservedObject var chatViewModel = ChatViewModel()
//    
//    @State var socketManager: MySocketManager
//    
//    @State var newMessage: String = ""
//    
//    @State var sheetShow: Bool = false
//    
//    @Binding var selectedFile: String
//    
//    @Binding var selectedFileName: String
//    
//    
//    var body: some View {
//        VStack {
//            ScrollViewReader { scrollView in
//                ScrollView(showsIndicators: false) {
//                    VStack(spacing: 8) {
//                        
//                        ForEach(chatViewModel.messages.reversed(), id: \.messageId) { message in
//                            ChatMessageRow(navigationPath: $navigationPath, selectedFile: $selectedFile, message: message)
//                                .id(message.messageId)
//                        }
//                        .onChange(of: chatViewModel.messages) { newValue in
//                            if let lastMessageId = chatViewModel.messages.first?.messageId {
//                                scrollView.scrollTo(lastMessageId, anchor: .bottom)
//                            }
//                        }
//                      
//                    }
//                }
//            }
//           
//            HStack {
//                
//                Button(action: {
//                    sheetShow = true
//                }, label: {
//                    Image("attach_file")
//                        .padding(10)
//                })
//                .sheet(isPresented: $sheetShow, content: {
//                    VStack {
//                        HStack{
//                            Text("Выберете вложение")
//                                .font(Font.custom("Roboto", size: 20).weight(.semibold))
//                                .padding(.top, 24)
//                            
//                            Spacer()
//                        }
//                        
//                        Button(action: {
//                            sheetShow = false
//                           
//                        }, label: {
//                            HStack{
//                                Image("picture_as_pdf")
//                                Text("Файл")
//                                    .foregroundColor(Color.black)
//                                Spacer()
//                            }
//                        })
//                        .padding(.top, 16)
//                        
//                        Button(action: {
//                            sheetShow = false
//                            
//                        }, label: {
//                            HStack{
//                                Image("folder_open")
//                                Text("Фото или видео")
//                                    .foregroundColor(Color.black)
//                                Spacer()
//                            }
//                        })
//                        Spacer()
//                        
//                    }
//                    .presentationDetents([.medium, .height(160)])
//                    .padding(.horizontal, 16)
//                })
//                
//                TextField("Введите сообщение", text: $newMessage)
//                
//                Button(action: {
//                    socketManager.sendMessage(text: newMessage)
//                    newMessage = ""
//                }, label: {
//                    Image("send")
//                        .padding(10)
//                })
//                
//            }
//           
//        }
//        .onAppear {
//            socketManager = MySocketManager(objectId: tappedObjectId, chatViewModel: chatViewModel)
//            socketManager.connect()
//            chatViewModel.fetchChatMessages(objectId: tappedObjectId, page: 0, limit: 400)
//            
//        }
//        .onDisappear {
//            socketManager.disconnect()
//        }
//    }
//}
//
//class ChatViewModel: ObservableObject {
//    @Published var messages: [ChatMessage] = []
//    @Published var currentPage: Int = 0
//    @Published var totalPages: Int = 1
//    
//    func fetchChatMessages(objectId: Int, page: Int, limit: Int, completion: (() -> Void)? = nil) {
//        let baseURL = "https://services-mskstroymir.ru/chat/messages"
//        
//        var urlComponents = URLComponents(string: baseURL)!
//        urlComponents.queryItems = [
//            URLQueryItem(name: "objectId", value: "\(objectId)"),
//            URLQueryItem(name: "page", value: "\(page)"),
//            URLQueryItem(name: "limit", value: "\(limit)")
//        ]
//        
//        guard let url = urlComponents.url else {
//            print("Invalid URL")
//            completion?()
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(AccessTokenHolder.shared.getAccessToken() ?? "")", forHTTPHeaderField: "Authorization")
//
//        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            defer { completion?() } // Гарантируем вызов completion после загрузки
//            
//            if let error = error {
//                print("Error fetching messages: \(error)")
//                return
//            }
//            
//            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
//                print("Server returned error")
//                return
//            }
//
//            guard let data = data else {
//                print("No data returned from server")
//                return
//            }
//            
//            do {
//                let decodedResponse = try JSONDecoder().decode(ChatMessageResponse.self, from: data)
//                DispatchQueue.main.async {
//                    if let newMessages = decodedResponse.content {
//                        // Фильтруем сообщения, которые уже есть в массиве
//                        let uniqueMessages = newMessages.filter { newMessage in
//                            !(self?.messages.contains(where: { $0.messageId == newMessage.messageId }) ?? false)
//                        }
//                        
//                        // Вставляем только уникальные сообщения в начало массива
//                        self?.messages.insert(contentsOf: uniqueMessages, at: 0)
//                    }
//                }
//            } catch {
//                print("Decoding error: \(error)")
//            }
//        }
//        
//        task.resume()
//    }
//
//}
//
//class MySocketManager: ObservableObject {
//    private var manager: SocketManager!
//    private var socket: SocketIOClient!
//    
//    @Published var isConnected = false
//    
//    private var objectId: Int
//    
//    private weak var chatViewModel: ChatViewModel? // Добавляем ссылку на ChatViewModel
//       
//       init(objectId: Int, chatViewModel: ChatViewModel) {
//           self.objectId = objectId
//           self.chatViewModel = chatViewModel // Инициализируем ссылку на ChatViewModel
//           setupSocket()
//       }
//    
//    private func setupSocket() {
//        guard let token = AccessTokenHolder.shared.getAccessToken() else {
//            print("Token not found in Keychain")
//            return
//        }
//       
//        let SOCKET_URL = "https://socket.services-mskstroymir.ru"
//        
//        manager = SocketManager(socketURL: URL(string: SOCKET_URL)!, config: [
//            .log(true),
//            .compress,
//            .forceWebsockets(true),
//            .secure(true),
//            .extraHeaders([
//                "Authorization": "Bearer \(token)",
//                "Object-Id": "\(objectId)"
//            ])
//        ])
//        
//        print("Socket создаётся с Object-Id: \(objectId) и пространством /whateverNamespace")
//        
//        socket = manager.socket(forNamespace: "/socket")
//       
//        socket.on(clientEvent: .connect) { [weak self] data, ack in
//            print("Socket connected")
//            self?.isConnected = true
//            self?.onConnected()
//        }
//
//        socket.on(clientEvent: .disconnect) { [weak self] data, ack in
//            print("Socket disconnected")
//            self?.isConnected = false
//            self?.onDisconnected()
//        }
//
//        socket.on(clientEvent: .error) { data, ack in
//            print("Socket connection error: \(data)")
//        }
//
//        socket.onAny { [weak self] event in
//            self?.handleIncoming(event: event)
//        }
//        socket.on("CHAT_MESSAGE_RESPONSE") { data, ack in
//            print("Received response: \(data)")
//        }
//        socket.on("NEW_MESSAGE") { [weak self] data, ack in
//            guard let self = self else { return }
//
//            if let messageData = data.first as? [String: Any],
//               let message = self.parseMessageData(messageData) {
//                DispatchQueue.main.async {
//                    self.chatViewModel?.messages.insert(message, at: 0)  // Добавляем сообщение в начало массива
//                    print("Новое сообщение добавлено в начало: \(message)")
//                }
//            }
//        }
//    }
//    // Функция для декодирования данных в модель ChatMessage
//    private func parseMessageData(_ data: [String: Any]) -> ChatMessage? {
//        do {
//            // Пытаемся извлечь внутренние данные из "data" (если они находятся внутри "data")
//            if let messageData = data["data"] as? [String: Any] {
//                // Преобразуем "data" в JSON-формат
//                let jsonData = try JSONSerialization.data(withJSONObject: messageData)
//                // Декодируем jsonData в ChatMessage
//                let decodedMessage = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
//                return decodedMessage
//            } else {
//                print("Ошибка: Не удалось найти ключ 'data' в JSON")
//                return nil
//            }
//        } catch {
//            print("Ошибка декодирования сообщения: \(error)")
//            return nil
//        }
//    }
//
//    
//    func connect() {
//        socket.connect()
//    }
//
//    func disconnect() {
//        socket.disconnect()
//    }
//
//    private func onConnected() {
//        print("Connected to socket with objectId: \(objectId)")
//    }
//    
//    private func onDisconnected() {
//        print("Disconnected from socket")
//    }
//
//    private func handleIncoming(event: SocketAnyEvent) {
//        // Обработка входящих сообщений
//        print("Incoming event: \(event)")
//    }
//    func sendMessage(text: String, filenames: [String] = []) {
//        guard isConnected else {
//            print("Cannot send message: Socket is not connected")
//            return
//        }
//        
//        let messageData: [String: Any] = [
//            "text": text,
//            "filenames": filenames
//        ]
//        
//        socket.emit("CHAT_MESSAGE", messageData)
//        print("Message sent: \(messageData)")
//    }
//}
//
//struct ChatMessageRow: View {
//    
//    @Binding var navigationPath: NavigationPath
//    
//    @Binding var selectedFile: String
//    
//    let message: ChatMessage
//    
//    @State private var isFullScreenImageShown = false
//    @State private var selectedIndex = 0
//    
//    var body: some View {
//        VStack {
//            if message.sender.userId == currentUserId {
//                // Блок сообщения текущего пользователя
//                HStack {
//                    
////                    Spacer()
//                    
//                    HStack(spacing: 4) {
//                        if message.attachments.medias.first(where: { $0.isImage }) != nil {
//                            
//                            VStack {
//                                if message.attachments.medias.count == 1 {
//                                    singleImageView(media: message.attachments.medias[0])
//                                } else if message.attachments.medias.count == 2 {
//                                    twoImagesView(media1: message.attachments.medias[0], media2: message.attachments.medias[1])
//                                } else if message.attachments.medias.count == 3 {
//                                    threeImagesView(message: message)
//                                } else if message.attachments.medias.count > 3 {
//                                    gridImageView(message: message)
//                                }
//                            }
//                            .fullScreenCover(isPresented: $isFullScreenImageShown) {
//                                FullScreenImageView(medias: message.attachments.medias, selectedIndex: $selectedIndex, isFullScreenImageShown: $isFullScreenImageShown)
//                            }
//                            
//                        } else if !message.attachments.files.isEmpty {
//                            
//                            ForEach(Array(message.attachments.files.enumerated()), id: \.offset) { index, file in
//                                VStack{
//                                    HStack {
//                                        // Левая цветная полоса
//                                        Rectangle()
//                                            .fill(myColors.Orange)
//                                            .frame(width: 8)
//                                            .frame(height: 58)
//                                           
//                                        
//                                        VStack(alignment: .leading) {
//                                            // Заголовок
//                                            Text(file.displayTitle)
//                                                .font(Font.custom("Roboto", size: 12).weight(.regular))
//                                                .lineLimit(1)
//                                            
//                                            HStack(alignment: .bottom) {
//                                                Text(file.contentType)
//                                                    .font(Font.custom("Roboto", size: 9).weight(.regular))
//                                                    .foregroundColor(myColors.textFieldOverlayGray)
//                                                    .padding(.bottom, 8)
//                                                
//                                                Text("\(file.fileSize)")
//                                                    .font(Font.custom("Roboto", size: 9).weight(.regular))
//                                                    .foregroundColor(myColors.textFieldOverlayGray)
//                                            }
//                                        }
//                                        .frame(height: 58)
//                                        .padding(.leading, 8)
//                                        
//                                        Spacer()
//                                        
//                                        VStack{
//                                            Image("downloadPdf")
//                                                .resizable()
//                                                .frame(width: 16, height: 16)
//                                                .padding(.top, 4)
//                                                .padding(.trailing, 4)
//                                            Spacer()
//                                        }
//                                        
//                                        
//                                    }
//                                    .frame(width: UIScreen.main.bounds.width * 0.6, alignment: .leading)
//                                    .frame(height: 58)
//                                    .background(.white)
//                                    .cornerRadius(8)
//                                    .padding(.leading, 8)
//                                    .padding(.top, 16)
//                                    .padding(.bottom, 16)
//                                    .padding(.trailing, 16)
//                                    .onTapGesture {
//                                        selectedFile = file.downloadUrl
//                                        navigationPath.append(Destination.pdfview)
//                                    }
//                                    
//                                   
//                                        Text(formatTimestamp(message.time))
//                                            .font(Font.custom("Roboto", size: 9).weight(.regular))
//                                            .foregroundColor(.white)
//                                            .padding(.trailing, 4)
//                                            .padding(.top, -16)
//                                            .frame(width: UIScreen.main.bounds.width * 0.6, alignment: .trailing)
//                                    
//                                   
//                                }
//                            }
//                        } else {
//                            // Если это не изображение, отображаем текст
//                            
//                            HStack{
//                                Text(message.text)
//                                    .font(Font.custom("Roboto", size: 14).weight(.regular))
//                                    .foregroundColor(Color.white)
//                                
//                                Text(formatTimestamp(message.time))
//                                    .font(Font.custom("Roboto", size: 9).weight(.regular))
//                                    .foregroundColor(.white)
//                                    .padding(.top, 16)
//                            }
//                            .padding(.vertical, 8)
//                            .padding(.leading, 16)
//                            .padding(.trailing, 8)
//                        }
//                    }
//                    .background(myColors.Orange)
//                    .clipShape(RoundedCornerShape(corners: [.topLeft, .topRight, .bottomLeft], radius: 16))
//                }
//            } else {
//                
//                HStack {
//                    VStack(alignment: .leading, spacing: 4) {
//                        HStack {
//                            Text("\(message.sender.name) \(message.sender.surname)")
//                                .font(Font.custom("Roboto", size: 14).weight(.medium))
//                                .foregroundColor(myColors.Orange)
//                            Spacer()
//                            Text(message.sender.jobTitle)
//                                .font(Font.custom("Roboto", size: 12).weight(.regular))
//                                .foregroundColor(.gray)
//                        }
//                        .padding(.vertical, 8)
//                        .padding(.leading, 8)
//                        .padding(.trailing, 16)
//                        
//                        if message.attachments.medias.first(where: { $0.isImage }) != nil {
//                            // Отображаем изображение, если есть вложение с изображением
//                            
//                            VStack {
//                                if message.attachments.medias.count == 1 {
//                                    singleImageView(media: message.attachments.medias[0])
//                                } else if message.attachments.medias.count == 2 {
//                                    twoImagesView(media1: message.attachments.medias[0], media2: message.attachments.medias[1])
//                                } else if message.attachments.medias.count == 3 {
//                                    threeImagesView(message: message)
//                                } else if message.attachments.medias.count > 3 {
//                                    gridImageView(message: message)
//                                }
//                            }
//                            .fullScreenCover(isPresented: $isFullScreenImageShown) {
//                                FullScreenImageView(medias: message.attachments.medias, selectedIndex: $selectedIndex, isFullScreenImageShown: $isFullScreenImageShown)
//                            }
//                            
//                        } else if !message.attachments.files.isEmpty {
//                            
//                            ForEach(Array(message.attachments.files.enumerated()), id: \.offset) { index, file in
//                                
//                                HStack {
//                                    // Левая цветная полоса
//                                    Rectangle()
//                                        .fill(myColors.Orange)
//                                        .frame(width: 8)
//                                        .frame(height: 58)
//                                        .clipShape(RoundedCornerShape(corners: [.topLeft, .bottomLeft], radius: 16))
//                                    
//                                    VStack(alignment: .leading) {
//                                        // Заголовок
//                                        Text(file.displayTitle)
//                                            .font(Font.custom("Roboto", size: 12).weight(.regular))
//                                            .lineLimit(1)
//                                        
//                                        HStack(alignment: .bottom) {
//                                            Text(file.contentType)
//                                                .font(Font.custom("Roboto", size: 9).weight(.regular))
//                                                .foregroundColor(myColors.textFieldOverlayGray)
//                                                .padding(.bottom, 8)
//
//                                            Text("\(file.fileSize)")
//                                                .font(Font.custom("Roboto", size: 9).weight(.regular))
//                                                .foregroundColor(myColors.textFieldOverlayGray)
//                                        }
//                                    }
//                                    .frame(height: 58)
//                                    .padding(.leading, 8)
//                                    
//                                    Spacer()
//                                    
//                                    VStack{
//                                        Image("downloadPdf")
//                                            .resizable()
//                                            .frame(width: 16, height: 16)
//                                            .padding(.top, 4)
//                                            .padding(.trailing, 4)
//                                        Spacer()
//                                    }
//                                       
//                                }
//                                .frame(width: UIScreen.main.bounds.width * 0.6, alignment: .leading)
//                                .frame(height: 58)
//                                .background(.white)
//                                .padding(.leading, 8)
//                                .cornerRadius(8)
//                                .onTapGesture {
//                                    selectedFile = file.downloadUrl
//                                    navigationPath.append(Destination.pdfview)
//                                }
//                            }
//                            // Время отправки
//                            HStack {
//                                Spacer()
//                                Text(formatTimestamp(message.time))
//                                    .font(Font.custom("Roboto", size: 9).weight(.regular))
//                                    .foregroundColor(.gray)
//                                    .padding(.trailing, 8)
//                                    .padding(.bottom, 4)
//                            }
//                            
//                        } else {
//                            // Отображаем текст сообщения
//                            Text(message.text)
//                                .font(Font.custom("Roboto", size: 14).weight(.regular))
//                                .padding(.leading, 8)
//                            
//                            // Время отправки
//                            HStack {
//                                Spacer()
//                                Text(formatTimestamp(message.time))
//                                    .font(Font.custom("Roboto", size: 9).weight(.regular))
//                                    .foregroundColor(.gray)
//                                    .padding(.trailing, 16)
//                            }
//                        }
//                        
//                    }
//                    .frame(width: UIScreen.main.bounds.width * 0.65, alignment: .leading)
//                    .background(myColors.textFieldOverlayGray)
//                    .clipShape(RoundedCornerShape(corners: [.topLeft, .topRight, .bottomRight], radius: 16))
//                    
////                    Spacer()
//                }
//            }
//        }
//        .padding(.horizontal, 8)
//    }
//    
//    private var currentUserId: String? {
//        loadAuthenticationResponse()?.user.userId
//    }
//    
//    // Функция для отображения одного изображения
//     func singleImageView(media: Media) -> some View {
//        KFImage.url(URL(string: media.originalUrl))
//            .requestModifier { request in
//                if let accessToken = AccessTokenHolder.shared.getAccessToken() {
//                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//                }
//            }
//            .placeholder {
//                ProgressView().frame(width: 76, height: 76)
//            }
//            .resizable()
////            .frame(width: UIScreen.main.bounds.width * 0.65, alignment: .leading)
//            .frame(maxWidth: 80)
//            .frame(maxHeight: 80)
//            .onTapGesture {
//                selectedIndex = 0
//                isFullScreenImageShown = true
//            }
//     }
//     // Функция для отображения двух изображений
//     func twoImagesView(media1: Media, media2: Media) -> some View {
//        HStack(spacing: 0) {
//            KFImage(URL(string: media1.originalUrl))
//                .requestModifier { request in
//                    if let accessToken = AccessTokenHolder.shared.getAccessToken() {
//                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//                    }
//                }
//                .placeholder {
//                    ProgressView().frame(width: 76, height: 76)
//                }
//                .resizable()
////                .frame(width: UIScreen.main.bounds.width * 0.65, alignment: .leading)
//                .frame(maxHeight: 80)
//                .frame(maxWidth: 80)
//                .onTapGesture {
//                    selectedIndex = 0
//                    isFullScreenImageShown = true
//                }
//            
//            KFImage(URL(string: media2.originalUrl))
//                .requestModifier { request in
//                    if let accessToken = AccessTokenHolder.shared.getAccessToken() {
//                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//                    }
//                }
//                .placeholder {
//                    ProgressView().frame(width: 76, height: 76)
//                }
//                .resizable()
////                .frame(width: UIScreen.main.bounds.width * 0.65, alignment: .leading)
//                .frame(maxWidth: 80)
//                .frame(maxHeight: 80)
//                .onTapGesture {
//                    selectedIndex = 1
//                    isFullScreenImageShown = true
//                }
//        }
//    }
//    // Функция для отображения трех изображений
//     func threeImagesView(message: ChatMessage) -> some View {
//        HStack(spacing: 0) {
//            KFImage(URL(string: message.attachments.medias[0].originalUrl))
//                .requestModifier { request in
//                    if let accessToken = AccessTokenHolder.shared.getAccessToken() {
//                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//                    }
//                }
//                .placeholder {
//                    ProgressView().frame(width: 76, height: 76)
//                }
//                .resizable()
//                .frame(height: 80)
//                .frame(width: 80)
////                .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
//                .onTapGesture {
//                    selectedIndex = 0
//                    isFullScreenImageShown = true
//                }
//            
//            VStack(spacing: 0) {
//                KFImage(URL(string: message.attachments.medias[1].originalUrl))
//                    .requestModifier { request in
//                        if let accessToken = AccessTokenHolder.shared.getAccessToken() {
//                            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//                        }
//                    }
//                    .placeholder {
//                        ProgressView().frame(width: 76, height: 76)
//                    }
//                    .resizable()
//                    .frame(height: 80)
//                    .frame(width: 80)
////                    .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
//                    .onTapGesture {
//                        selectedIndex = 1
//                        isFullScreenImageShown = true
//                    }
//                
//                KFImage(URL(string: message.attachments.medias[2].originalUrl))
//                    .requestModifier { request in
//                        if let accessToken = AccessTokenHolder.shared.getAccessToken() {
//                            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//                        }
//                    }
//                    .placeholder {
//                        ProgressView().frame(width: 76, height: 76)
//                    }
//                    .resizable()
//                    .frame(height: 80)
//                    .frame(width: 80)
////                    .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
//                    .onTapGesture {
//                        selectedIndex = 2
//                        isFullScreenImageShown = true
//                    }
//            }
//        }
//    }
//    
//     func gridImageView(message: ChatMessage) -> some View {
//            VStack(spacing: 0) {
//                HStack(spacing: 0) {
//                    ForEach(message.attachments.medias.prefix(2), id: \.id) { media in
//                        KFImage(URL(string: media.originalUrl))
//                            .requestModifier { request in
//                                if let accessToken = AccessTokenHolder.shared.getAccessToken() {
//                                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//                                }
//                            }
//                            .placeholder {
//                                ProgressView().frame(width: 76, height: 76)
//                            }
//                            .resizable()
//                            .frame(height: 80)
//                            .frame(width: 80)
////                            .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
//                            .onTapGesture {
//                                selectedIndex = message.attachments.medias.firstIndex(where: { $0.id == media.id }) ?? 0
//                                isFullScreenImageShown = true
//                            }
//                    }
//                }
//                
//                HStack(spacing: 0) {
//                    KFImage(URL(string: message.attachments.medias[2].originalUrl))
//                        .requestModifier { request in
//                            if let accessToken = AccessTokenHolder.shared.getAccessToken() {
//                                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//                            }
//                        }
//                        .placeholder {
//                            ProgressView().frame(width: 76, height: 76)
//                        }
//                        .resizable()
//                        .frame(height: 80)
//                        .frame(width: 80)
////                        .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
//                        .onTapGesture {
//                            selectedIndex = 2
//                            isFullScreenImageShown = true
//                        }
//                    
//                    ZStack {
//                        KFImage(URL(string: message.attachments.medias[3].originalUrl))
//                            .requestModifier { request in
//                                if let accessToken = AccessTokenHolder.shared.getAccessToken() {
//                                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//                                }
//                            }
//                            .placeholder {
//                                ProgressView().frame(width: 76, height: 76)
//                            }
//                            .resizable()
//                            .frame(height: 80)
//                            .frame(width: 80)
////                            .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
//                            .onTapGesture {
//                                selectedIndex = 3
//                                isFullScreenImageShown = true
//                            }
//                        
//                        if message.attachments.medias.count > 4 {
//                            Color.black.opacity(0.6)
//                            Text("+\(message.attachments.medias.count - 4)")
//                                .foregroundColor(.white)
//                                .font(.headline)
//                        }
//                    }
//                }
//            }
//        }
//}
//
//struct FullScreenImageView: View {
//    let medias: [Media]
//    @Binding var selectedIndex: Int
//    @Binding var isFullScreenImageShown: Bool
//
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack(alignment: .topTrailing) {
//                Color.black.ignoresSafeArea()
//
//                TabView(selection: $selectedIndex) {
//                    ForEach(Array(medias.enumerated()), id: \.offset) { index, media in
//                        KFImage(URL(string: media.originalUrl))
//                            .requestModifier { request in
//                                if let accessToken = AccessTokenHolder.shared.getAccessToken() {
//                                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//                                }
//                            }
//                            .placeholder {
//                                ProgressView().frame(width: 76, height: 76)
//                            }
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: geometry.size.width, height: geometry.size.height)
//                            .tag(index)
//                    }
//                }
//                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
//
//                // Кнопка закрытия
//                Button(action: {
//                    isFullScreenImageShown = false
//                }) {
//                    Image(systemName: "xmark.circle.fill")
//                        .foregroundColor(.white)
//                        .font(.largeTitle)
//                        .padding()
//                }
//            }
//        }
//    }
//}
//
//struct ChatMessageResponse: Codable {
//    let totalPages: Int?
//    let totalElements: Int?
//    let size: Int?
//    let content: [ChatMessage]?
//    let number: Int?
//    let sort: Sort?
//    let numberOfElements: Int?
//    let pageable: Pageable?
//    let first: Bool?
//    let last: Bool?
//    let empty: Bool?
//}
//
//struct ChatMessage: Identifiable, Codable, Hashable, Equatable {
//    var id: String { messageId }
//    let messageId: String
//    let sender: Sender
//    let time: Int
//    let text: String
//    let attachments: Attachments
//}
//
//struct Sender: Codable, Hashable, Equatable {
//    let userId: String
//    let name: String
//    let surname: String
//    let isEmployee: Bool?
//    let patronymic: String
//    let imageUrl: String?
//    let jobTitle: String
//    
//}
//
//struct Attachments: Codable, Hashable, Equatable {
//    let medias: [Media]
//    let files: [File]
//}
//
//struct File: Codable, Hashable, Equatable {
//    let filename: String
//    let contentType: String
//    let displayTitle: String
//    let downloadUrl: String
//    let `extension`: String
//    let fileSize: Int
//}
//
//struct RoundedCornerShape: Shape {
//    var corners: UIRectCorner
//    var radius: CGFloat
//
//    func path(in rect: CGRect) -> Path {
//        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
//        return Path(path.cgPath)
//    }
//}
//
//func loadAuthenticationResponse() -> AuthenticationResponse? {
//    if let authData = UserDefaults.standard.data(forKey: "authResponse") {
//        do {
//            let decoder = JSONDecoder()
//            let authResponse = try decoder.decode(AuthenticationResponse.self, from: authData)
//            return authResponse
//        } catch {
//            print("Ошибка при загрузке AuthenticationResponse: \(error.localizedDescription)")
//        }
//    }
//    return nil
//}
//
//func formatTimestamp(_ timestamp: Int) -> String {
//    let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
//    let formatter = DateFormatter()
//    formatter.dateFormat = "HH:mm"
//    formatter.locale = Locale(identifier: "en_US")
//    formatter.timeZone = TimeZone.current
//    return formatter.string(from: date)
//}
//
//
//
////                        // Обновляем текущую страницу и общее количество страниц
////                        self?.currentPage = page
////                        self?.totalPages = decodedResponse.totalPages ?? 1
////
////                        print("Current page: \(self?.currentPage ?? 1), Total pages: \(self?.totalPages ?? 1)")
////                        // Выводим список сообщений в консоль
////                                                print("Fetched Messages:")
////                                                for message in newMessages {
////                                                    print("Message ID: \(message.messageId), Text: \(message.text), Sender: \(message.sender), time \(formatTimestamp(message.time)), timestamp \(message.time)")
////
////                                                    // Выводим информацию о медиафайлах
////                                                    if !message.attachments.medias.isEmpty {
////                                                        print("  Media Attachments:")
////                                                        for media in message.attachments.medias {
////                                                            print("    - Original URL: \(media.originalUrl)")
////                                                            if let thumbnailUrl = media.thumbnailUrl {
////                                                                print("      Thumbnail URL: \(thumbnailUrl)")
////                                                            }
////                                                            print("      Content Type: \(media.contentType)")
////                                                            print("      Display Title: \(media.displayTitle)")
////                                                            print("      Is Video: \(media.isVideo)")
////                                                            print("      Is Image: \(media.isImage)")
////                                                        }
////                                                    } else {
////                                                        print("  No Media Attachments")
////                                                    }
//
////                                                    // Выводим информацию о файлах
////                                                    if !message.attachments.files.isEmpty {
////                                                        print("  File Attachments:")
////                                                        for file in message.attachments.files {
////                                                            print("    - Filename: \(file.filename)")
////                                                            print("      Content Type: \(file.contentType)")
////                                                            print("      Display Title: \(file.displayTitle)")
////                                                            print("      Download URL: \(file.downloadUrl)")
////                                                            print("      Extension: \(file.extension)")
////                                                            print("      File Size: \(file.fileSize) bytes")
////                                                        }
////                                                    } else {
////                                                        print("  No File Attachments")
////                                                    }
////                                                }
////
//
//
//
//
//
//
////if message.attachments.medias.count == 1 {
////    // Если вложение - изображение, отображаем его
////    ZStack{
////        // Если вложение - изображение, отображаем его
////        KFImage.url(URL(string: "\(imageMedia.thumbnailUrl ?? imageMedia.originalUrl)"))
////            .requestModifier { request in
////                if let accessToken = AccessTokenHolder.shared.getAccessToken() {
////                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
////                }
////            }
////            .placeholder {
////                ProgressView().frame(width: 76, height: 76)
////            }
////            .resizable()
////            .frame(width: UIScreen.main.bounds.width * 0.65, alignment: .leading)
////            .frame(maxHeight: 175)
////            .clipShape(RoundedCornerShape(corners: [.topLeft, .topRight, .bottomRight], radius: 16))
////        
////
////        
////    }
////} else if message.attachments.medias.count == 2 {
////    // Отображение двух изображений
////    HStack(spacing: 0) {
////        ForEach(message.attachments.medias.prefix(2), id: \.id) { media in
////            KFImage(URL(string: media.originalUrl))
////                .requestModifier { request in
////                    if let accessToken = AccessTokenHolder.shared.getAccessToken() {
////                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
////                    }
////                }
////                .placeholder {
////                    ProgressView().frame(width: 76, height: 76)
////                }
////                .resizable()
////                .frame(width: UIScreen.main.bounds.width * 0.65, alignment: .leading)
////                .frame(maxHeight: 260)
////        }
////        .clipShape(RoundedCornerShape(corners: [.topLeft, .topRight, .bottomRight], radius: 16))
////    }
////} else if message.attachments.medias.count == 3 {
////    // Отображение трёх изображений
////    HStack(spacing: 0) {
////        KFImage(URL(string: message.attachments.medias[0].originalUrl))
////            .requestModifier { request in
////                if let accessToken = AccessTokenHolder.shared.getAccessToken() {
////                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
////                }
////            }
////            .placeholder {
////                ProgressView().frame(width: 76, height: 76)
////            }
////            .resizable()
////            .frame(height: 130)
////            .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
////        
////        VStack(spacing: 0) {
////            KFImage(URL(string: message.attachments.medias[1].originalUrl))
////                .requestModifier { request in
////                    if let accessToken = AccessTokenHolder.shared.getAccessToken() {
////                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
////                    }
////                }
////                .placeholder {
////                    ProgressView().frame(width: 76, height: 76)
////                }
////                .resizable()
////                .frame(height: 130)
////                .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
////            
////            KFImage(URL(string: message.attachments.medias[2].originalUrl))
////                .requestModifier { request in
////                    if let accessToken = AccessTokenHolder.shared.getAccessToken() {
////                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
////                    }
////                }
////                .placeholder {
////                    ProgressView().frame(width: 76, height: 76)
////                }
////                .resizable()
////                .frame(height: 130)
////                .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
////        }
////    }
////    .frame(width: UIScreen.main.bounds.width * 0.65, alignment: .leading)
////    .frame(maxHeight: 260)
////    
////} else if message.attachments.medias.count > 3 {
////   
////    // Отображение плитки из четырёх изображений
////       VStack(spacing: 0) {
////           HStack(spacing: 0) {
////               // Отображение первых двух изображений
////               ForEach(message.attachments.medias.prefix(2), id: \.id) { media in
////                   KFImage(URL(string: media.originalUrl))
////                       .requestModifier { request in
////                           if let accessToken = AccessTokenHolder.shared.getAccessToken() {
////                               request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
////                           }
////                       }
////                       .placeholder {
////                           ProgressView().frame(width: 76, height: 76)
////                       }
////                       .resizable()
////                       .frame(height: 130)
////                       .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
////                     
////               }
////           }
////           
////           HStack(spacing: 0) {
////               // Отображение третьего изображения
////               KFImage(URL(string: message.attachments.medias[2].originalUrl))
////                   .requestModifier { request in
////                       if let accessToken = AccessTokenHolder.shared.getAccessToken() {
////                           request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
////                       }
////                   }
////                   .placeholder {
////                       ProgressView().frame(width: 76, height: 76)
////                   }
////                   .resizable()
////                   .frame(height: 130)
////                   .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
////                 
////               
////               // Четвёртое изображение с наложением оставшегося количества
////               ZStack {
////                   KFImage(URL(string: message.attachments.medias[3].originalUrl))
////                       .requestModifier { request in
////                           if let accessToken = AccessTokenHolder.shared.getAccessToken() {
////                               request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
////                           }
////                       }
////                       .placeholder {
////                           ProgressView().frame(width: 76, height: 76)
////                       }
////                       .resizable()
////                       .frame(height: 130)
////                       .frame(width: UIScreen.main.bounds.width * 0.325, alignment: .leading)
////                      
////                   
////                   // Наложение для отображения количества оставшихся изображений
////                   if message.attachments.medias.count > 4 {
////                       Color.black.opacity(0.6)
////                           .frame(width: 30, height: 30)
////                           .clipShape(RoundedRectangle(cornerRadius: 8))
////                       
////                       Text("+\(message.attachments.medias.count - 4)")
////                           .foregroundColor(.white)
////                           .font(.headline)
////                   }
////               }
////           }
////       }
////       .frame(width: UIScreen.main.bounds.width * 0.65, alignment: .leading)
////       .frame(maxHeight: 260)
////}
