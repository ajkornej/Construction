//
//  ContentView.swift
//  Construction
//
//  Created by Корнеев Александр on 04.12.2025.
//

import SwiftUI
import KeychainSwift
import MapboxMaps
import Network
import Kingfisher

// Главный экран приложения
struct ContentView: View {
    
    // MARK: - ViewModel
    
    @StateObject private var viewModel = ContentViewModel()
    
    // MARK: - Child ViewModels
    
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var createCheckViewModel = createCheckViewModel()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            VStack {
                if viewModel.isAuthenticated {
                    makeMainView()
                } else {
                    WelcomeView(navigationPath: $viewModel.navigationPath)
                }
            }
            .navigationDestination(for: ConfirmationDestination.self) { destination in
                ConfirmationView(
                    navigationPath: $viewModel.navigationPath,
                    phoneNumber: destination.phone,
                    key: destination.key
                )
            }
            .navigationDestination(for: WebViewDestination.self) { destination in
                StroymirWebView(url: destination.url, title: destination.title)
            }
            .navigationDestination(for: Destination.self) { destination in
                destinationView(for: destination)
            }
        }
        .accentColor(.black)
        .onAppear(perform: handleOnAppear)
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkNotification)) { notification in
            handleDeepLinkNotification(notification)
        }
        .overlay {
            NetworkBanner()
        }
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private func makeMainView() -> some View {
        mainView(
            navigationPath: $viewModel.navigationPath,
            dataResponseObjectAll: $viewModel.dataResponseObjectAll,
            tappedObjectId: $viewModel.tappedObjectId,
            medias: $viewModel.medias,
            selectedObject: $viewModel.selectedObject,
            showingBottomSheet: $viewModel.showingBottomSheet,
            selectedFile: $viewModel.selectedFile,
            authResponse: $viewModel.authResponse
        )
    }
    
    @ViewBuilder
    private func destinationView(for destination: Destination) -> some View {
        switch destination {
        case .contentview:
            ContentView()
            
        case .firstview:
            WelcomeView(navigationPath: $viewModel.navigationPath)
            
        case .costcalculation:
            costCalculation(navigationPath: $viewModel.navigationPath)
            
        case .phoneinput:
            LoginView(navigationPath: $viewModel.navigationPath)
            
        case .mainview:
            makeMainView()
            
        case .objectDetails:
            objectDetails(
                navigationPath: $viewModel.navigationPath,
                tappedObjectId: $viewModel.tappedObjectId,
                medias: $viewModel.medias,
                selectedFile: $viewModel.selectedFile,
                selectedFileName: $viewModel.selectedFileName,
                selectedObject: $viewModel.selectedObject,
                showingBottomSheet: $viewModel.showingBottomSheet,
                isShowingObjectDetails: $viewModel.isShowingObjectDetails,
                capturedMedia: $viewModel.capturedMedia,
                dataResponseObjectAll: $viewModel.dataResponseObjectAll,
                needsRefresh: $viewModel.needsRefresh,
                tappedTaskId: $viewModel.tappedTaskId
            )
            
        case .aboutapp:
            aboutApp(navigationPath: $viewModel.navigationPath)
            
        case .pdfview:
            pdfView(
                navigationPath: $viewModel.navigationPath,
                selectedFile: $viewModel.selectedFile,
                selectedFileName: $viewModel.selectedFileName
            )
            
        case .mapboxmapview:
            MapboxMapView(
                dataResponseObjectAll: $viewModel.dataResponseObjectAll,
                tappedObjectId: $viewModel.tappedObjectId,
                navigationPath: $viewModel.navigationPath,
                selectedObject: $viewModel.selectedObject,
                authResponse: $viewModel.authResponse
            )
            
        case .druganddropreportsphoto:
            drugAndDropReportsPhoto(
                navigationPath: $viewModel.navigationPath,
                capturedMedia: $viewModel.capturedMedia,
                tappedObjectId: $viewModel.tappedObjectId
            )
            
        case .camerastruct:
            cameraStruct(
                navigationPath: $viewModel.navigationPath,
                capturedMedia: $viewModel.capturedMedia
            )
            
        case .createdocumentview:
            CreateDocumentView(
                navigationPath: $viewModel.navigationPath,
                tappedObjectId: $viewModel.tappedObjectId,
                generatedPDFURL: $viewModel.generatedPDFURL
            )
            
        case .camerastructdoc:
            CameraStructDoc(
                navigationPath: $viewModel.navigationPath,
                capturedMediaDoc: $viewModel.capturedMediaDoc
            )
            
        case .drugAnddropdocument:
            DrugAndDropDocument(
                navigationPath: $viewModel.navigationPath,
                capturedMediaDoc: $viewModel.capturedMediaDoc,
                tappedObjectId: $viewModel.tappedObjectId,
                generatedPDFURL: $viewModel.generatedPDFURL
            )
            
        case .openobject:
            OpenObject(
                tappedObjectId: $viewModel.tappedObjectId,
                navigationPath: $viewModel.navigationPath,
                generatedPDFURL: $viewModel.generatedPDFURL,
                needsRefresh: $viewModel.needsRefresh,
                dataResponseObjectAll: $viewModel.dataResponseObjectAll,
                capturedMedia: $viewModel.capturedMedia,
                capturedMediaDoc: $viewModel.capturedMediaDoc
            )
            
        case .alerts:
            Alerts(
                navigationPath: $viewModel.navigationPath,
                alertData: $viewModel.alertData,
                tappedObjectId: $viewModel.tappedObjectId,
                medias: $viewModel.medias,
                selectedObject: $viewModel.selectedObject,
                selectedPriority: $viewModel.selectedPriority,
                selectedType: $viewModel.selectedType,
                selectedObjectId: $viewModel.selectedObjectId,
                selectedPriorities: $viewModel.selectedPriorities,
                selectedTypes: $viewModel.selectedTypes,
                selectedObjectIds: $viewModel.selectedObjectIds,
                tappedTaskId: $viewModel.tappedTaskId
            )
            
        case .alertsfilters:
            AlertsFilters(
                alertData: $viewModel.alertData,
                navigationPath: $viewModel.navigationPath,
                selectedPriority: $viewModel.selectedPriority,
                selectedType: $viewModel.selectedType,
                selectedObjectId: $viewModel.selectedObjectId,
                selectedPriorities: $viewModel.selectedPriorities,
                selectedTypes: $viewModel.selectedTypes,
                selectedObjectIds: $viewModel.selectedObjectIds,
                dataResponseObjectAll: $viewModel.dataResponseObjectAll
            )
            
        case .chat:
            ChatViewNew(
                tappedObjectId: $viewModel.tappedObjectId,
                chatViewModel: ChatViewModel(),
                authResponse: $viewModel.authResponse,
                selectedFile: $viewModel.selectedFile,
                selectedFileName: $viewModel.selectedFileName,
                navigationPath: $viewModel.navigationPath
            )
            
        case .openObjectCamera:
            openObjectCamera(
                navigationPath: $viewModel.navigationPath,
                capturedMediaDoc: $viewModel.capturedMediaDoc
            )
            
        case .openObjectDrugAndDropDocument:
            openObjectDrugAndDropDocument(
                navigationPath: $viewModel.navigationPath,
                capturedMediaDoc: $viewModel.capturedMediaDoc,
                tappedObjectId: $viewModel.tappedObjectId,
                generatedPDFURL: $viewModel.generatedPDFURL
            )
            
        case .createcheck:
            createCheck(
                navigationPath: $viewModel.navigationPath,
                tappedObjectId: $viewModel.tappedObjectId,
                viewModel: createCheckViewModel,
                generatedPDFURL: $viewModel.generatedPDFURL,
                capturedMediaDoc: $viewModel.capturedMediaDoc
            )
            
        case .createcheckcamera:
            CreateCheckCamera(
                navigationPath: $viewModel.navigationPath,
                capturedMediaDoc: $viewModel.capturedMediaDoc
            )
            
        case .druganddropcheck:
            DrugAndDropCheck(
                navigationPath: $viewModel.navigationPath,
                capturedMediaDoc: $viewModel.capturedMediaDoc,
                generatedPDFURL: $viewModel.generatedPDFURL
            )
            
        case .taskvew:
            ObjectTaskView(
                viewModel: ObjectTaskViewModel(),
                navigationPath: $viewModel.navigationPath,
                tappedTaskId: $viewModel.tappedTaskId
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func handleOnAppear() {
        viewModel.syncUserData()
        configureKingfisher()
    }
    
    private func configureKingfisher() {
        let downloader = KingfisherManager.shared.downloader
        downloader.sessionConfiguration.httpMaximumConnectionsPerHost = 3
        downloader.downloadTimeout = 15
    }
    
    private func handleDeepLinkNotification(_ notification: NotificationCenter.Publisher.Output) {
        guard let userInfo = notification.userInfo,
              let type = userInfo["type"] as? String,
              let id = userInfo["id"] as? String else { return }
        
        let openChat = (userInfo["openChat"] as? String) == "true"
        viewModel.handleDeepLink(type: type, id: id, openChat: openChat)
    }
}
