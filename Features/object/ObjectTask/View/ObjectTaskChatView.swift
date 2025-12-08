//
//  ObjectTaskChatView.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 06.03.2025.
//

import Foundation
import ExyteChat
import SwiftUI

struct ObjectTaskChatView: View {
    
    @Binding var navigationPath: NavigationPath
    @Binding var tappedTaskId: String
    
    @Binding var authResponse: AuthenticationResponse?
    
    @StateObject var viewModel = ObjectTaskChatViewModel()
    
    @State var textBinding: String = ""
    
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
    
    @State private var attachments: [ExyteChat.Attachment] = []
    
    var body: some View {
        ChatView(
            messages: viewModel.messages, chatType: .conversation,
            didSendMessage: { draft in
                if !draft.text.isEmpty || !viewModel.attachments.isEmpty {
                    viewModel.postTaskChat(
                        taskId: tappedTaskId, text: draft.text,
                        fileURLs: viewModel.attachments.map { $0.full }
                    )
                }
            },
            messageBuilder: { message, _, _, _, _, showAttachmentClosure in
                
                VStack{
                    if message.user.id == authResponse?.user.userId {
                        HStack{
                            Spacer()
                                .frame(width: 50)
                            MyMessageView(
                                message: message, selectedFile: $selectedFile, selectedFileName: $selectedFileName, navigationPath: $navigationPath
                            )
                        }
                    } else {
                        HStack{
//                            OtherMessageView(message: message, authResponse: $authResponse, viewModel: viewModel, selectedFile: $selectedFile, selectedFileName: $selectedFileName, navigationPath: $navigationPath)
                            Spacer()
                        }
                    }
                }
                .onTapGesture {
                    let imageAttachments = message.attachments.filter {
                        $0.type == .image && !$0.full.absoluteString.lowercased().hasSuffix(".pdf")
                        
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
                    
//                    AttachmentInputView(attachments: $viewModel.attachments, uploadStates: $uploadStates, viewModel: viewModel, isUploading: $viewModel.isUploading)
                    
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
                                AttachmentTypeSheetView(showingFilePicker: $showingFilePicker, showAttachmentTypeSheet: $showAttachmentTypeSheet, showingPhotoPicker: $showingPhotoPicker, attachments: $viewModel.attachments, activeSheet: $activeSheet)
                            case .photoPicker:
                                PhotoPickerView(attachments: $viewModel.attachments)
                            case .filePicker:
                                VStack {
                                    NewDocumentPicker(attachments: $viewModel.attachments) { urlsWithSize in
                                        let currentCount = $viewModel.attachments.count
                                        let remainingCount = viewModel.sharedMaxAttachmentCount - currentCount
                                        
                                        guard remainingCount > 0 else {
                                            print("❌ Превышен общий лимит в \(viewModel.sharedMaxAttachmentCount) вложений")
                                            return
                                        }
                                        
                                        let allowedUrlsWithSize = Array(urlsWithSize.prefix(remainingCount))
                                        let newAttachments = allowedUrlsWithSize.compactMap { url, fileSize -> ExyteChat.Attachment? in
                                            url.toChatAttachment(fileSize: fileSize) // Передаем размер файла
                                        }
                                        viewModel.attachments.append(contentsOf: newAttachments)
                                        
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
                        
                        Button(action: {
                            inputViewActionClosure(.send) // Отправка сообщения
                        }, label: {
                            Image("send")
                        })
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    }
                }
            )
            .enableLoadMore(pageSize: 100,  { lastMessage in
//                await chatViewModel.loadOlderMessages(objectId: tappedObjectId, lastMessage: lastMessage)
            })
            .showMessageTimeView(false)
            .onAppear {
               
                if messages.isEmpty {
                    
//                    chatViewModel.fetchChatMessages(objectId: tappedTaskId, page: 0) { newMessages in
//                        DispatchQueue.main.async {
//                            if newMessages.isEmpty {
//                                print("No new messages fetched.")
//                            } else {
//                                // Удаляем дубликаты перед добавлением
//                                let uniqueMessages = newMessages.filter { newMessage in
//                                    !chatViewModel.messages.contains { $0.id == newMessage.id }
//                                }
//                                
//                                chatViewModel.messages.append(contentsOf: uniqueMessages)
//                                chatViewModel.messages.sort { $1.createdAt > $0.createdAt }
//                            }
//                        }
//                    }
                }
            }
            .onDisappear{
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
    }
}
