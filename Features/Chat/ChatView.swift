//
//  ChatView.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 21.11.2024.
//

import SkeletonUI
import SwiftUI
import ExyteChat
import Combine
import AVKit
import Kingfisher
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation


enum UploadState {
    case none       // Файл не загружен
    case loading    // Файл в процессе загрузки
    case success    // Файл успешно загружен
    case failure    // Ошибка загрузки файла
}

enum SheetType: Identifiable {
    case attachmentType
    case photoPicker
    case filePicker

    // Реализация протокола Identifiable
    var id: String {
        switch self {
        case .attachmentType:
            return "attachmentType"
        case .photoPicker:
            return "photoPicker"
        case .filePicker:
            return "filePicker"
        }
    }
}

func generateThumbnail(for videoURL: URL) -> UIImage? {
    let asset = AVAsset(url: videoURL)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    
    // Добавляем обработку ошибок
    do {
        let cgImage = try generator.copyCGImage(
            at: CMTimeMake(value: 1, timescale: 60),
            actualTime: nil
        )
        return UIImage(cgImage: cgImage)
    } catch {
        print("Thumbnail generation error: \(error.localizedDescription)")
        return nil
    }
}

func isVideoAttachment(_ attachment: ExyteChat.Attachment) -> Bool {
    switch attachment.type {
    case .video:
        print("Attachment type: .video")
        return true
    case .file(let file):
        print("Attachment type: .file, contentType: \(file.contentType), extension: \(file.extension)")
        let videoContentTypes = ["video/mp4", "video/quicktime", "video/x-matroska"]
        let videoExtensions = ["mp4", "mov", "mkv"]
        return videoContentTypes.contains(file.contentType) || videoExtensions.contains(file.extension.lowercased())
    case .image:
        print("Attachment type: .image")
        return false
    }
}

struct ChatView: View {
    
    @Binding var tappedObjectId: String
    
    @StateObject var chatViewModel = ChatViewModel()
    
    @State var textBinding: String = ""
    
    @Binding var authResponse: AuthenticationResponse?
    
    @State private var messages: [Message] = []
    
    @State var showAttachmentTypeSheet: Bool = false
    
    @State var showingPhotoPicker: Bool = false
    
    @State var showingFilePicker: Bool = false
    
    @State private var uploadStates: [String: UploadState] = [:]
    
    @State private var activeSheet: SheetType?
    
    @State private var selectedFiles: [URL] = []
    
    @State private var showMediaGallery = false
    @State private var selectedImageAttachments: [Media] = []
    @State private var selectedIndex = 0
    @State private var mediaComment = ""
    
    @Binding var selectedFile: String
    @Binding var selectedFileName: String
    
    @Binding var navigationPath: NavigationPath
    
    @State private var attachments: [ExyteChat.Attachment] = []
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack{
            ChatView(
                messages: chatViewModel.messages, didSendMessage: { draft in
                    if !draft.text.isEmpty || !chatViewModel.attachments.isEmpty {
                        chatViewModel.sendMessage(
                            text: draft.text,
                            fileURLs: chatViewModel.attachments.map { $0.full }
                        )
                    }
                },
                messageBuilder: { message, _, _, _, _, showAttachmentClosure in
                    
                    VStack{
                        if message.user.id == authResponse?.user.userId {
                            HStack{
                                Spacer()
                                   
                                MyMessageView(
                                    message: message, selectedFile: $selectedFile, selectedFileName: $selectedFileName, navigationPath: $navigationPath
                                )
                            }
                        } else {
                            HStack{
                                OtherMessageView(message: message, authResponse: $authResponse, chatViewModel: chatViewModel, selectedFile: $selectedFile, selectedFileName: $selectedFileName, navigationPath: $navigationPath)
                                
                                Spacer()
                            }
                        }
                    }
                    .onTapGesture {
                        isFocused = false
                        let imageAttachments = message.attachments.filter {
                            ($0.type == .image || $0.type == .video) && !$0.full.absoluteString.lowercased().hasSuffix(".pdf")
                            
                        }
                        
                        if !imageAttachments.isEmpty {
                            
                            // Преобразование imageAttachments в массив Media
                            let mediaItems = imageAttachments.map { attachment in
                                Media(
                                    originalUrl: attachment.full.absoluteString,
                                    isVideo: attachment.type == .video,
                                    isImage: attachment.type == .image
                                )
                            }
                            
                            // Обновление состояния для открытия галереи
                            selectedImageAttachments = mediaItems
                            selectedIndex = 0
                            showMediaGallery = true
                        }
                    }
                },
                inputViewBuilder: { textBinding, attachmentsBinding, _, _, inputViewActionClosure, _ in
                    VStack {
                        
                        AttachmentInputView(attachments: $chatViewModel.attachments, uploadStates: $uploadStates, viewModel: chatViewModel, isUploading: $chatViewModel.isUploading)
                        
                        HStack {
                            Button(action: {
                                activeSheet = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    activeSheet = .attachmentType
                                }
                            }, label: {
                                Image("attach_file")
                            })
                            .sheet(item: $activeSheet) { sheet in
                                switch sheet {
                                case .attachmentType:
                                    AttachmentTypeSheetView(showingFilePicker: $showingFilePicker, showAttachmentTypeSheet: $showAttachmentTypeSheet, showingPhotoPicker: $showingPhotoPicker, attachments: $chatViewModel.attachments, activeSheet: $activeSheet)
                                case .photoPicker:
                                    PhotoPickerView(attachments: $chatViewModel.attachments)
                                case .filePicker:
                                    VStack {
                                        NewDocumentPicker(attachments: $chatViewModel.attachments) { urlsWithSize in
                                            let currentCount = chatViewModel.attachments.count
                                            let remainingCount = chatViewModel.sharedMaxAttachmentCount - currentCount
                                            
                                            guard remainingCount > 0 else {
                                                print("❌ Превышен общий лимит в \(chatViewModel.sharedMaxAttachmentCount) вложений")
                                                return
                                            }
                                            
                                            let allowedUrlsWithSize = Array(urlsWithSize.prefix(remainingCount))
                                            let newAttachments = allowedUrlsWithSize.compactMap { url, fileSize -> ExyteChat.Attachment? in
                                                url.toChatAttachment(fileSize: fileSize) // Передаем размер файла
                                            }
                                            chatViewModel.attachments.append(contentsOf: newAttachments)
                                            
                                            if urlsWithSize.count > allowedUrlsWithSize.count {
                                                print("ℹ️ Добавлено только \(allowedUrlsWithSize.count) из \(urlsWithSize.count)")
                                                // Optionally: showAlert(message: "Добавлено только \(allowedUrlsWithSize.count) из \(urlsWithSize.count)")
                                            }
                                        }
                                    }
                                    .ignoresSafeArea()
                                }
                            }
                            
                            TextField("Введите сообщение", text: textBinding)
                                .focused($isFocused)
                                .onChange(of: textBinding.wrappedValue) { newValue in
                                    if !newValue.isEmpty {
                                        chatViewModel.sendTypingStatus(isTyping: true)
                                        // Запускаем таймер для автоматического сброса статуса
                                        chatViewModel.typingTimer?.invalidate()
                                        chatViewModel.typingTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                                            chatViewModel.sendTypingStatus(isTyping: false)
                                        }
                                    } else {
                                        chatViewModel.sendTypingStatus(isTyping: false)
                                    }
                                }
                            
                            Button(action: {
                                let text = textBinding.wrappedValue
                                let isTextValid = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                if isTextValid || !chatViewModel.attachments.isEmpty {
                                    inputViewActionClosure(.send) // Отправка сообщения
                                }
                            }, label: {
                                let text = textBinding.wrappedValue
                                let isTextValid = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                if isTextValid || !chatViewModel.attachments.isEmpty {
                                    Image("send")
                                } else {
                                    Image("sendgray")
                                }
                            })
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
            )
            .enableLoadMore(pageSize: 100,  { lastMessage in
                await chatViewModel.loadOlderMessages(objectId: tappedObjectId, lastMessage: lastMessage)
            })
            .onAppear {
                chatViewModel.setupSocket(objectId: tappedObjectId)
                chatViewModel.connect()
                if messages.isEmpty {
                    chatViewModel.isMessageLoaded = false
                    chatViewModel.fetchChatMessages(objectId: tappedObjectId, page: 0) { newMessages in
                        DispatchQueue.main.async {
                            if newMessages.isEmpty {
                                print("No new messages fetched.")
                                chatViewModel.isMessageLoaded = true
                            } else {
                                // Удаляем дубликаты перед добавлением
                                let uniqueMessages = newMessages.filter { newMessage in
                                    !chatViewModel.messages.contains { $0.id == newMessage.id }
                                }
                                chatViewModel.messages.append(contentsOf: uniqueMessages)
                                chatViewModel.messages.sort { $1.createdAt > $0.createdAt }
                                chatViewModel.isMessageLoaded = true
                            }
                        }
                    }
                }
            }
            .onDisappear{
                chatViewModel.disconnect()
            }
            .fullScreenCover(isPresented: $showMediaGallery) {
                MediaGalleryView(
                    medias: selectedImageAttachments,
                    selectedIndex: $selectedIndex,
                    mediasReports: $selectedImageAttachments,
                    mediaComment: $mediaComment,
                    showGallery: $showMediaGallery
                )
            }
            
            if chatViewModel.messages.isEmpty && chatViewModel.isMessageLoaded {
                VStack{
                    Image("visual-empty")
                        .resizable()
                        .frame(width: 140, height: 140)
                    
                    Text("Пока что здесь \nничего нет")
                        .multilineTextAlignment(.center)
                        .font(Fonts.Font_Headline2)
                    
                    Text("Напишите в чат первое \nсообщение, и вам \nобязательно ответят")
                        .multilineTextAlignment(.center)
                        .font(Fonts.Font_Callout)
                }
            }
            
            if chatViewModel.isErrror {
                
                Spacer()
                
                Text("Ошибка. Что-то пошло не так...")
                
                Spacer()
            }
            
            if !chatViewModel.isMessageLoaded {
                ProgressView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar{
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    navigationPath.removeLast(1)
                }) {
                    VStack{
                        
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 17, weight: .medium)) // Размер и стиль стрелки
                            
                            VStack(alignment: .leading, spacing: 0){
                                Text("Назад")
                                    .font(.system(size: 17)) // Размер текста
                                
                                if !chatViewModel.typingUsers.isEmpty {
                                    
                                    Text("\(chatViewModel.typingUsers.joined(separator: ", ")) печатает...")
                                        .font(Fonts.Font_Headline3)
                                        .foregroundColor(Colors.textFieldOverlayGray)
                                    
                                } else {
                                    if !chatViewModel.connectionStatus.isEmpty {
                                        Text("\(chatViewModel.connectionStatus)")
                                            .font(Fonts.Font_Headline3)
                                            .foregroundColor(Colors.textFieldOverlayGray)
                                        
                                    }
                                }
                            }
                        }
                        .foregroundColor(.black) // Цвет текста и иконки
                        
                    }
                }
            }
        }
    }
}

func shouldShowUserName(for message: Message, in messages: [Message], authUserId: String?) -> Bool {
    guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
        return false
    }

    // Условие 1: Предыдущее сообщение от текущего пользователя
    let isAfterCurrentUserMessage: Bool
    if index > 0 { // Проверяем, что index - 1 находится в пределах массива
        let previousMessage = messages[index - 1]
        isAfterCurrentUserMessage = previousMessage.user.id == authUserId && message.user.id != authUserId
    } else {
        isAfterCurrentUserMessage = false
    }

    // Условие 2: Это самое первое сообщение за день
    let isFirstMessageForDay = isFirstMessageForDay(message, in: messages)

    // Показываем имя, если выполняется хотя бы одно из условий
    return isAfterCurrentUserMessage || isFirstMessageForDay
}

func isFirstMessageForDay(_ message: Message, in messages: [Message]) -> Bool {
    let calendar = Calendar.current
    let messageDay = calendar.startOfDay(for: message.createdAt)

    // Найти самое раннее сообщение за день (в убывающем массиве это будет первое совпавшее)
    guard let earliestMessageForDay = messages.first(where: {
        calendar.isDate($0.createdAt, inSameDayAs: messageDay)
    }) else {
        return false
    }

    return earliestMessageForDay.id == message.id
}

func formatTime(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm" // Формат времени d MMM yyyy'г.'
    return formatter.string(from: date)
}

func formatFileSize(_ sizeInBytes: Int) -> String {
    let sizeInMB = Double(sizeInBytes) / (1024 * 1024)
    return String(format: "%.2f MB", sizeInMB)
}

func singleImageView(media: ExyteChat.Attachment, attachments: [ExyteChat.Attachment]) -> some View {
    print("Processing media: \(media)")
    return VStack(spacing: 0) {
        ZStack {
            KFImage.url(media.thumbnail)
                .requestModifier { request in
                    if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    }
                }
                .loadDiskFileSynchronously(false)
                .cacheOriginalImage()
                .placeholder {
                    Rectangle()
                        .skeleton(
                            with: true,
                            animation: .pulse(),
                            appearance: .solid(color: .gray.opacity(0.3)),
                            shape: .rectangle
                        )
                        .frame(width: 260, height: 260)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 260, height: 260)
                .clipped()
            
            if isVideoAttachment(media) {
                VideoPlayIconView()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

func twoImagesView(media1: ExyteChat.Attachment, media2: ExyteChat.Attachment) -> some View {
    HStack(spacing: 0) {
       
        ZStack{
            KFImage.url(media1.thumbnail)
                .requestModifier { request in
                    if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    }
                }
                .loadDiskFileSynchronously(false)
                .cacheOriginalImage()
                .placeholder {
                    Rectangle()
                        .skeleton(
                            with: true,
                            animation: .pulse(),
                            appearance: .solid(color: .gray.opacity(0.3)),
                            shape: .rectangle
                        )
                        .frame(width: 130 /*UIScreen.main.bounds.width * 0.325*/, height: 260, alignment: .leading)
                    
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 130 /*UIScreen.main.bounds.width * 0.325*/, height: 260, alignment: .leading)
            
            if isVideoAttachment(media1) {
                VideoPlayIconView()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
      
        ZStack{
            KFImage.url(media2.thumbnail)
                .requestModifier { request in
                    if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    }
                }
                .loadDiskFileSynchronously(false)
                .cacheOriginalImage()
                .placeholder {
                    Rectangle()
                        .skeleton(
                            with: true,
                            animation: .pulse(),
                            appearance: .solid(color: .gray.opacity(0.3)),
                            shape: .rectangle
                        )
                        .frame(width: 130 /*UIScreen.main.bounds.width * 0.325*/, height: 260, alignment: .leading)
                    
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 130 /*UIScreen.main.bounds.width * 0.325*/, height: 260, alignment: .leading)
            
            if isVideoAttachment(media2) {
                VideoPlayIconView()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

func threeImagesView(message: ExyteChat.Message) -> some View {
    let images = message.attachments.filter { $0.type == .image }
    
    return HStack(spacing: 0) {
       
        ZStack{
            KFImage.url(images[0].full)
                .requestModifier { request in
                    if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    }
                }
                .loadDiskFileSynchronously(false)
                .cacheOriginalImage()
                .placeholder {
                    Rectangle()
                        .skeleton(
                            with: true,
                            animation: .pulse(),
                            appearance: .solid(color: .gray.opacity(0.3)),
                            shape: .rectangle
                        )
                        .frame(width: 130, height: 260)
                    
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 130, height: 260)
                .clipped() // Обрезает изображение, чтобы оно соответствовало размеру
            
            if isVideoAttachment(images[0]) {
                VideoPlayIconView()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    
        
        VStack(spacing: 0) {
           
            ZStack{
                KFImage.url(images[1].full)
                    .requestModifier { request in
                        if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                        }
                    }
                    .loadDiskFileSynchronously(false)
                    .cacheOriginalImage()
                    .placeholder {
                        Rectangle()
                            .skeleton(
                                with: true,
                                animation: .pulse(),
                                appearance: .solid(color: .gray.opacity(0.3)),
                                shape: .rectangle
                            )
                            .frame(width: 130, height: 130, alignment: .leading)
                        
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 130, height: 130)
                    .clipped() // Обрезает изображение, чтобы оно соответствовало размеру
                
                if isVideoAttachment(images[1]) {
                    VideoPlayIconView()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
         
            ZStack{
                KFImage.url(images[2].full)
                    .requestModifier { request in
                        if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                        }
                    }
                    .loadDiskFileSynchronously(false)
                    .cacheOriginalImage()
                    .placeholder {
                        Rectangle()
                            .skeleton(
                                with: true,
                                animation: .pulse(),
                                appearance: .solid(color: .gray.opacity(0.3)),
                                shape: .rectangle
                            )
                            .frame(width: 130 /*UIScreen.main.bounds.width * 0.325*/, height: 130, alignment: .leading)
                        
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 130, height: 130)
                    .clipped() // Обрезает изображение, чтобы оно соответствовало размеру
                
                if isVideoAttachment(images[2]) {
                    VideoPlayIconView()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

func gridImageView(message: ExyteChat.Message) -> some View {
    let images = message.attachments.filter { $0.type == .image }
    
    return VStack(spacing: 0) {
        HStack(spacing: 0) {
            ForEach(images.prefix(2), id: \.id) { media in
                ZStack{
                    KFImage.url(media.thumbnail)
                        .requestModifier { request in
                            if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                            }
                        }
                        .loadDiskFileSynchronously(false)
                        .cacheOriginalImage()
                        .placeholder {
                            Rectangle()
                                .skeleton(
                                    with: true,
                                    animation: .pulse(),
                                    appearance: .solid(color: .gray.opacity(0.3)),
                                    shape: .rectangle
                                )
                                .frame(width: 130 /*UIScreen.main.bounds.width * 0.325*/, height: 130, alignment: .leading)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 130 /*UIScreen.main.bounds.width * 0.325*/, height: 130, alignment: .leading)
                        .clipped()
                    
                    if isVideoAttachment(media) {
                        VideoPlayIconView()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        
        HStack(spacing: 0) {
            ForEach(images.dropFirst(2).prefix(2), id: \.id) { media in
                ZStack {
                    KFImage.url(media.thumbnail)
                        .requestModifier { request in
                            if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                            }
                        }
                        .loadDiskFileSynchronously(false)
                        .cacheOriginalImage()
                        .placeholder {
                            Rectangle()
                                .skeleton(
                                    with: true,
                                    animation: .pulse(),
                                    appearance: .solid(color: .gray.opacity(0.3)),
                                    shape: .rectangle
                                )
                                .frame(width: 130 /*UIScreen.main.bounds.width * 0.325*/, height: 130, alignment: .leading)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 130 /*UIScreen.main.bounds.width * 0.325*/, height: 130, alignment: .leading)
                        .clipped()
                    
                    if isVideoAttachment(media) {
                        VideoPlayIconView()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Добавляем индикатор для оставшихся изображений
                    if media == images[3], images.count > 4 {
                        Color.black.opacity(0.6)
                        Text("+\(images.count - 3)")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
            }
        }
    }
    .frame(width: 260 /*UIScreen.main.bounds.width * 0.65*/, alignment: .leading)
}

struct MyMessageView: View {
    
    let message: ExyteChat.Message
    
    @State private var showGallery = false
    @State private var selectedIndex = 0
    @State private var mediasReports: [Media] = []

    @Binding var selectedFile: String
    @Binding var selectedFileName: String
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            
            // Файловые вложения
            let fileAttachments: [ExyteChat.Attachment] = message.attachments.filter { attachment in
                if case .file = attachment.type {
                    return true
                    
                }
                return false
                
            }
            
            if !message.text.isEmpty && message.attachments.first(where: { [.image, .video].contains($0.type) }) != nil && !fileAttachments.isEmpty {
                Text("\(message.text)  ")
                    .font(Fonts.Font_Callout)
                    .foregroundColor(Color.white)
            }
            
            // Проверка на наличие изображений или видео
            if message.attachments.first(where: { [.image, .video].contains($0.type) }) != nil {
                
                if !message.text.isEmpty {
                    Text("\(message.text)  ")
                        .font(Fonts.Font_Callout)
                        .foregroundColor(Color.white)
                        .frame(alignment: .trailing)
                        .padding(.vertical, 8)
                }
                    
                ZStack{
                    VStack(spacing: 0) {
                        let imageAttachments = message.attachments.filter {
                            ($0.type == .image || $0.type == .video) && !$0.full.absoluteString.lowercased().hasSuffix(".pdf")
                        }
                        
                        // Отображение изображений в зависимости от количества
                        switch imageAttachments.count {
                        case 1:
                            singleImageView(media: imageAttachments[0], attachments: imageAttachments)
                        case 2:
                            twoImagesView(media1: imageAttachments[0], media2: imageAttachments[1])
                        case 3:
                            threeImagesView(message: message)
                        default:
                            gridImageView(message: message)
                        }
                        
                    }
                    
                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                            Text(formatTime(from: message.createdAt))
                                .font(Fonts.Font_ChatTime)
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Color.black.opacity(0.5)
                                        .cornerRadius(8)
                                )
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                            }
                    }
                }
                .frame(width: 260 /*UIScreen.main.bounds.width * 0.65*/, alignment: .leading)
            }
            
            ForEach(fileAttachments, id: \.id) { attachment in
                if case let .file(file) = attachment.type {
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            // Оранжевая полоска слева
                            Rectangle()
                                .foregroundColor(Colors.textFieldOverlayGray)
                                .frame(width: 8)
                                .clipShape(RoundedCornerShape(corners: [.topLeft, .bottomLeft], radius: 4))

                            // Основное содержимое файла
                            VStack(alignment: .leading, spacing: 4) {
                                // Название файла
                                Text("\(file.displayTitle)")
                                    .font(Fonts.Font_Footnote)
                                    .padding(.leading, 8)
                                    .padding(.top, 8)
                                    .lineLimit(2) // Максимум 2 строки
                                    .multilineTextAlignment(.leading)

                                // Дополнительная информация (расширение и размер)
                                HStack {
                                    Text(file.extension)
                                        .font(Fonts.Font_ChatTime)
                                        .foregroundColor(Colors.textFieldOverlayGray)
                                    
                                    Text("\(formatFileSize(file.fileSize))")
                                        .font(Fonts.Font_ChatTime)
                                        .foregroundColor(Colors.textFieldOverlayGray)
                                    
                                    Spacer()
                                }
                                .padding(.leading, 8)
                                .padding(.top, 4)
                                .padding(.bottom, 8)
                            }

                            // Иконка для загрузки файла
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(Colors.orange)
                                .padding(.trailing, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .frame(width: 260)
                    .onTapGesture {
                        print("tappedOnfile")
                        
                        selectedFile = file.downloadUrl
                        selectedFileName = file.displayTitle
                        navigationPath.append(Destination.pdfview)
                    }
                }
            }
            
            if message.attachments.first(where: { [.image, .video].contains($0.type) }) == nil && fileAttachments.isEmpty {
                HStack {
                    Text(message.text)
                        .font(Fonts.Font_Callout)
                        .foregroundColor(Color.white)
                        .padding(.vertical, 4)
                        .padding(.leading, 8)
                    
                    Text(formatTime(from: message.createdAt))
                        .font(Fonts.Font_ChatTime)
                        .foregroundColor(Color.white)
                        .padding(.top, 15)
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                }
            }
        }
        .background(Colors.orange)
        .clipShape(RoundedCornerShape(corners: [.topLeft, .topRight, .bottomLeft], radius: 16))
        .padding(.top, 4)
        .padding(.horizontal, 8)
    }
}

struct OtherMessageView: View {
   
    let message: ExyteChat.Message
    
    @Binding var authResponse: AuthenticationResponse?
    
    @ObservedObject var chatViewModel: ChatViewModel
    
    @State private var showGallery = false
    @State private var selectedIndex = 0
    @State private var mediasReports: [Media] = []
    
    @Binding var selectedFile: String
    @Binding var selectedFileName: String
    @Binding var navigationPath: NavigationPath

    var body: some View {
        
        // Сообщения других пользователей
        VStack(alignment: .leading, spacing: 0) {

            // Файловые вложения
            let fileAttachments: [ExyteChat.Attachment] = message.attachments.filter { attachment in
                if case .file = attachment.type {
                    return true
                }
                return false
            }
            // Проверка на наличие изображений или видео
            if message.attachments.first(where: { [.image, .video].contains($0.type) }) != nil {
                
                if shouldShowUserName(for: message, in: chatViewModel.messages, authUserId: authResponse?.user.userId) {
                    HStack {
                        Text(message.user.name)
                            .font(Fonts.Font_Headline3)
                            .foregroundColor(Colors.orange)
                        
                        Spacer()
                        
                        if let role = message.params["role"] {
                            Text("\(String(describing: role))")
                                .font(Fonts.Font_Footnote)
                                .foregroundColor(Colors.textFieldOverlayGray)
                        } else {
                            Text("Role not available")
                                .font(Fonts.Font_Footnote)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
                
                if !message.text.isEmpty {
                    Text("\(message.text)  ")
                        .font(Fonts.Font_Callout)
                        .foregroundColor(Color.black)
                        .frame(alignment: .trailing)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                }
                    
                ZStack{
                    let imageAttachments = message.attachments.filter {
                        ($0.type == .image || $0.type == .video) && !$0.full.absoluteString.lowercased().hasSuffix(".pdf")
                    }
                    
                    // Отображение изображений в зависимости от количества
                    switch imageAttachments.count {
                    case 1:
                        singleImageView(media: imageAttachments[0], attachments: imageAttachments)
                    case 2:
                        twoImagesView(media1: imageAttachments[0], media2: imageAttachments[1])
                    case 3:
                        threeImagesView(message: message)
                    default:
                        gridImageView(message: message)
                    }
                    
                    VStack{
                        
                        Spacer()
                        
                        HStack{
                            Spacer()
                            Text(formatTime(from: message.createdAt))
                                .font(Fonts.Font_ChatTime)
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Color.black.opacity(0.5)
                                        .cornerRadius(8)
                                )
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                            }
                    }
                }
                .frame(width: 260, alignment: .leading)
            }
            
            ForEach(fileAttachments, id: \.id) { attachment in
                if case let .file(file) = attachment.type {
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            // Оранжевая полоска слева
                            Rectangle()
                                .foregroundColor(Colors.orange)
                                .frame(width: 8)
                                .clipShape(RoundedCornerShape(corners: [.topLeft, .bottomLeft], radius: 4))

                            // Основное содержимое файла
                            VStack(alignment: .leading, spacing: 4) {
                                // Название файла
                                Text("\(file.displayTitle)")
                                    .font(Fonts.Font_Footnote)
                                    .padding(.leading, 8)
                                    .padding(.top, 8)
                                    .lineLimit(2) // Максимум 2 строки
                                    .multilineTextAlignment(.leading)

                                // Дополнительная информация (расширение и размер)
                                HStack {
                                    Text(file.extension)
                                        .font(Fonts.Font_ChatTime)
                                        .foregroundColor(Colors.textFieldOverlayGray)
                                    
                                    Text("\(formatFileSize(file.fileSize))")
                                        .font(Fonts.Font_ChatTime)
                                        .foregroundColor(Colors.textFieldOverlayGray)
                                    
                                    Spacer()
                                }
                                .padding(.leading, 8)
                                .padding(.top, 4)
                                .padding(.bottom, 8)
                            }

                            // Иконка для загрузки файла
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(Colors.orange)
                                .padding(.trailing, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .frame(width: 240)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    .onTapGesture {
                        print("tappedOnfile")
                        selectedFile = file.downloadUrl
                        selectedFileName = file.displayTitle
                        navigationPath.append(Destination.pdfview)
                    }
                }
            }
            
            if message.attachments.first(where: { [.image, .video].contains($0.type) }) == nil && fileAttachments.isEmpty {
                
                if shouldShowUserName(for: message, in: chatViewModel.messages, authUserId: authResponse?.user.userId) {
                    HStack {
                        Text(message.user.name)
                            .font(Fonts.Font_Headline3)
                            .foregroundColor(Colors.orange)
                           
                        Spacer()
                        
                        if let role = message.params["role"] as? String {
                            Text("\(role)")
                                .font(Fonts.Font_Footnote)
                                .foregroundColor(Colors.textFieldOverlayGray)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
                
                HStack {
                    Text(message.text)
                        .font(Fonts.Font_Callout)
                        .foregroundColor(Color.black)
                    
                    Spacer()
                    
                    Text(formatTime(from: message.createdAt))
                        .font(Fonts.Font_ChatTime)
                        .foregroundColor(Colors.textFieldOverlayGray)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .background(Colors.lightGray2)
        .clipShape(RoundedCornerShape(corners: [.topLeft, .topRight, .bottomRight], radius: 16))
        .padding(.bottom, 4)
        .padding(.horizontal, 8)
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    var onFilesPicked: ([URL]) -> Void
    var onError: (Error) -> Void = { error in
        print("Error: \(error.localizedDescription)")
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 10
        configuration.filter = .any(of: [.images, .videos])

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        private let serialQueue = DispatchQueue(label: "com.photoPicker.copiedURLs") // Последовательная очередь для потокобезопасности

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            var copiedURLs: [URL] = []
            let dispatchGroup = DispatchGroup()

            for result in results {
                if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) ||
                    result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {

                    dispatchGroup.enter()
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.item.identifier) { url, error in
                        guard let sourceURL = url, error == nil else {
                            self.parent.onError(error ?? NSError(domain: "PhotoPickerError", code: -1, userInfo: nil))
                            dispatchGroup.leave()
                            return
                        }

                        do {
                            let uniqueDestinationURL = self.uniqueFileURL(for: sourceURL)
                            try FileManager.default.copyItem(at: sourceURL, to: uniqueDestinationURL)

                            // Добавляем URL потокобезопасно
                            self.serialQueue.sync {
                                copiedURLs.append(uniqueDestinationURL)
                            }
                        } catch {
                            self.parent.onError(error)
                        }
                        dispatchGroup.leave()
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.parent.onFilesPicked(copiedURLs)
            }
        }

        // Метод для генерации уникального пути файла
        func uniqueFileURL(for fileURL: URL) -> URL {
            let fileManager = FileManager.default
            let tmpDirectory = fileManager.temporaryDirectory

            let originalFileName = fileURL.deletingPathExtension().lastPathComponent
            let fileExtension = fileURL.pathExtension
            let uniqueSuffix = UUID().uuidString

            let uniqueFileName = "\(originalFileName)_\(uniqueSuffix).\(fileExtension)"
            return tmpDirectory.appendingPathComponent(uniqueFileName)
        }
    }
}

struct PhotoPickerView: View {
    @Binding var attachments: [ExyteChat.Attachment]
    private let sharedMaxAttachmentCount = 10
    
    var body: some View {
        PhotoPicker { urls in
            let currentCount = attachments.count
            let remainingCount = sharedMaxAttachmentCount - currentCount
            
            if currentCount >= sharedMaxAttachmentCount {
                print("❌ Превышен общий лимит в \(sharedMaxAttachmentCount) вложений")
            } else {
                let allowedURLs = urls.prefix(remainingCount)
                attachments.append(contentsOf: allowedURLs.map {
                    // Определяем тип вложения
                    let type: AttachmentType = UTType(filenameExtension: $0.pathExtension)?.conforms(to: .movie) ?? false
                        ? .video
                        : .image
                    
                    return ExyteChat.Attachment(
                        id: UUID().uuidString,
                        thumbnail: $0,
                        full: $0,
                        type: type // Используем правильный тип
                    )
                })
            }
        }
        .ignoresSafeArea()
    }
}

struct NewDocumentPicker: UIViewControllerRepresentable {
    @Binding var attachments: [ExyteChat.Attachment]
    var onFilesPicked: ([(URL, Int)]) -> Void
    private let sharedMaxAttachmentCount = 10
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.pdf,
            UTType.text,
            UTType.rtf,
            UTType.data
        ], asCopy: true)
        documentPicker.delegate = context.coordinator
        documentPicker.allowsMultipleSelection = true
        return documentPicker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: NewDocumentPicker

        init(_ parent: NewDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let currentCount = parent.attachments.count
            let remainingCount = parent.sharedMaxAttachmentCount - currentCount
            
            if currentCount >= parent.sharedMaxAttachmentCount {
                print("❌ Превышен общий лимит в \(parent.sharedMaxAttachmentCount) файлов")
            } else {
                // Add only up to the remaining count
                let allowedURLs = Array(urls.prefix(remainingCount))
                
                // Получаем размер файла для каждого URL
                let filesWithSize = allowedURLs.map { url -> (URL, Int) in
                    let fileSize = getFileSize(from: url)
                    return (url, fileSize)
                }
                
                // Передаем размер файла в onFilesPicked
                parent.onFilesPicked(filesWithSize)
            }
        }

        func getFileSize(from url: URL) -> Int {
            do {
                let resources = try url.resourceValues(forKeys: [.fileSizeKey])
                let fileSize = resources.fileSize ?? 0
                return fileSize
            } catch {
                print("Error getting file size: \(error)")
                return 0
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Document picker was cancelled.")
        }
    }
}

struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct AttachmentInputView: View {
    @Binding var attachments: [ExyteChat.Attachment]
    @Binding var uploadStates: [String: UploadState]
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isUploading: Bool
    
    var body: some View {
        VStack {
            if isUploading || !attachments.isEmpty { // Корректное условие
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(attachments.indices, id: \.self) { index in
                            let attachment = attachments[index]
                            ZStack(alignment: .topTrailing) {
                                if attachment.type == .image {
                                    Image(uiImage: UIImage(contentsOfFile: attachment.full.path) ?? UIImage())
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else if attachment.type == .video {
                                    ZStack {
                                        if let thumbnail = generateThumbnail(for: attachment.full) {
                                            Image(uiImage: thumbnail)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else {
                                            Color.gray
                                                .overlay(Text("Invalid Video"))
                                        }
                                        
                                        VideoPlayIconView()
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else if case let .file(file) = attachment.type {
                                    VStack {
                                        Text(file.displayTitle)
                                            .font(Fonts.Font_ChatTime)
                                            .lineLimit(4)
                                            .frame(maxWidth: 80, alignment: .leading)
                                            .padding(6)
                                        
                                        Spacer()
                                        
                                        HStack {
                                            Text(".\(file.extension)")
                                                .font(Fonts.Font_ChatTime)
                                                .foregroundColor(.white)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 4)
                                            
                                            Spacer()
                                                
                                            Text("\(formatFileSize(file.fileSize))")
                                                .font(Fonts.Font_ChatTime)
                                                .foregroundColor(.white)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 4)
                                            
                                        }
                                        .background(Colors.orange)
                                        .clipShape(RoundedCornerShape(corners: [.bottomLeft, .bottomRight], radius: 8))
                                    }
                                    .frame(width: 80, height: 80)
                                    .background(Colors.lightGray2)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                // Прогресс загрузки
                                if let upload = viewModel.uploadProgress.first(where: { $0.fileURL == attachment.full }) {
                                    if upload.isCompleted {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                    } else {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                    }
                                } else {
                                    // Иконка удаления (крестик)
                                    Button(action: {
                                        withAnimation {
                                            if let index = attachments.firstIndex(where: { $0.id == attachment.id }) {
                                                attachments.remove(at: index)
                                            }
                                        }
                                    }) {
                                        Image("xmark")
                                            .padding(.top, 4)
                                    }
                                }
                            }
                            
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct AttachmentTypeSheetView: View {
    
    @Binding var showingFilePicker: Bool
    @Binding var showAttachmentTypeSheet: Bool
    @Binding var showingPhotoPicker: Bool
    @Binding var attachments: [ExyteChat.Attachment]
    @Binding var activeSheet: SheetType?
    
    var body: some View {
        VStack {
            HStack{
                Text("Выберите вложение")
                    .font(Font.custom("Roboto", size: 20).weight(.semibold))
                    .padding(.top, 24)
                
                Spacer()
            }
            
            Button(action: {
                activeSheet = nil // Закрываем текущий лист
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                       activeSheet = .filePicker // Открываем следующий лист
                   }
            }, label: {
                HStack{
                    Image("pdf")
                    Text("Файл")
                        .foregroundColor(Colors.textFieldOverlayGray)
                    Spacer()
                }
            })
            .padding(.top, 16)
            .disabled(attachments.count >= 10) // Блокировка кнопки
            
                                    
            Button(action: {
                activeSheet = nil // Закрываем текущий лист
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                       activeSheet = .photoPicker // Открываем следующий лист
                   }
            }, label: {
                HStack{
                    Image("perm_media")
                    Text("Фото или видео")
                        .foregroundColor(Colors.textFieldOverlayGray)
                    Spacer()
                }
            })
            .disabled(attachments.count >= 10) // Блокировка кнопки
            Spacer()
        }
        .presentationDetents([.medium, .height(160)])
        .padding(.horizontal, 16)
        .ignoresSafeArea()
    }
}

extension UIApplication {
    func endEditing() {
        keyWindow?.endEditing(true)
    }
}
