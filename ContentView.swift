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
    @State var navigationPath = NavigationPath()
    @State var isAuthenticated = false
    @State var tappedObjectId: String = ""
    @State var allUserNames: String = ""
    @State var tappedAdress: String = ""
    @State private var medias: [Media] = []
    @State var selectedObject: ObjectResponse = ObjectResponse(
        objectId: "",
        address: "",
        latitude: 0.0,
        longitude: 0.0,
        imageFilename: nil,
        startDate: nil,
        endDate: nil,
        comment: "",
        users: [],
        primaryClientId: nil,
        status: "",
        reportExpired: false, problemStatus: false,
        cashInfo: nil,
        fullAddress: "",
        imageUrl: nil
    )

    @State var tappedTaskId: String = ""
    @State var zoomLevel: CGFloat = 10.0
    @State var selectedFile = ""
    @State var selectedFileName = ""
    @State var showingBottomSheet = false
    
    @State private var capturedImages: [UIImage] = []
    
    @State private var capturedVideos: [URL] = []
    
    @State private var capturedMedia: [CapturedMedia] = []
    
    @State var capturedMediaDoc: [CapturedMediaDocument] = []
    
    @State var dataResponseObjectAll: [ObjectResponse] = []

    @State var isShowingObjectDetails = false
    
    @State var onlyPhoto: Bool = false
    
    @State private var generatedPDFURL: URL?  // Для хранения URL сгенерированного PDF
    
    @State var alertData: [AlertResponse] = []
    
    @State var selectedPriority: String = ""
    @State var selectedType: String = ""
    @State var selectedObjectId: String = ""
    
    @State private var selectedPriorities: [String] = []
    @State private var selectedTypes: [String] = []
    @State private var selectedObjectIds: [String] = []
    
    @State var needsRefresh = false
    
    @State private var authResponse: AuthenticationResponse?
    
    @StateObject var chatViewModel = ChatViewModel()
    
    @StateObject var createcheckviewModel = createCheckViewModel()
    
    
    init() {
        
        AppStartupManager.handleFirstLaunch()
        // Проверяем наличие accessToken при инициализации
        _isAuthenticated = State(initialValue: checkAccessToken())
        
    }
    
    var body: some View {
        
        NavigationStack(path: $navigationPath) {
            VStack {
                // Отображение соответствующего экрана на основе статуса аутентификации
                if isAuthenticated {
                    mainView(navigationPath: $navigationPath, dataResponseObjectAll: $dataResponseObjectAll,
                             tappedObjectId: $tappedObjectId,
                             medias: $medias,
                             selectedObject: $selectedObject, showingBottomSheet: $showingBottomSheet, selectedFile: $selectedFile, authResponse: $authResponse)
                } else {
                    WelcomeView(navigationPath: $navigationPath)
                }
            }
            .navigationDestination(for: ConfirmationDestination.self) { destination in
                ConfirmationView(navigationPath: $navigationPath, phoneNumber: destination.phone, key: destination.key)
            }
            .navigationDestination(for: WebViewDestination.self) { destination in
                StroymirWebView(url: destination.url, title: destination.title)
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .contentview:
                    ContentView()
                case .firstview:
                    WelcomeView(navigationPath: $navigationPath)
                case .costcalculation:
                    costCalculation(navigationPath: $navigationPath)
                case .phoneinput:
                    LoginView(navigationPath: $navigationPath)
                case .mainview:
                    mainView(navigationPath: $navigationPath, dataResponseObjectAll: $dataResponseObjectAll,
                             tappedObjectId: $tappedObjectId,
                             medias: $medias,
                             selectedObject: $selectedObject, showingBottomSheet: $showingBottomSheet, selectedFile: $selectedFile, authResponse: $authResponse)
                case .objectDetails:
                    objectDetails(navigationPath: $navigationPath, tappedObjectId: $tappedObjectId, medias: $medias, selectedFile: $selectedFile, selectedFileName: $selectedFileName, selectedObject: $selectedObject, showingBottomSheet: $showingBottomSheet, isShowingObjectDetails: $isShowingObjectDetails, capturedMedia: $capturedMedia, dataResponseObjectAll: $dataResponseObjectAll, needsRefresh: $needsRefresh, tappedTaskId: $tappedTaskId)
                case .aboutapp:
                    aboutApp(navigationPath: $navigationPath)
                case .pdfview:
                    pdfView(navigationPath: $navigationPath, selectedFile: $selectedFile, selectedFileName: $selectedFileName)
                case .mapboxmapview:
                    MapboxMapView(dataResponseObjectAll: $dataResponseObjectAll, tappedObjectId: $tappedObjectId, navigationPath: $navigationPath, selectedObject: $selectedObject, authResponse: $authResponse)
                case .druganddropreportsphoto:
                    drugAndDropReportsPhoto(navigationPath: $navigationPath, capturedMedia: $capturedMedia, tappedObjectId: $tappedObjectId)
                case .camerastruct:
                    cameraStruct(navigationPath: $navigationPath, capturedMedia: $capturedMedia)
                case .createdocumentview:
                    CreateDocumentView(navigationPath: $navigationPath, tappedObjectId: $tappedObjectId, generatedPDFURL: $generatedPDFURL)
                case .camerastructdoc:
                    CameraStructDoc(navigationPath: $navigationPath, capturedMediaDoc: $capturedMediaDoc)
                case .drugAnddropdocument:
                    DrugAndDropDocument(navigationPath: $navigationPath, capturedMediaDoc: $capturedMediaDoc, tappedObjectId: $tappedObjectId, generatedPDFURL: $generatedPDFURL)
                case .openobject:
                    OpenObject(tappedObjectId: $tappedObjectId, navigationPath: $navigationPath, generatedPDFURL: $generatedPDFURL, needsRefresh: $needsRefresh, dataResponseObjectAll: $dataResponseObjectAll, capturedMedia: $capturedMedia, capturedMediaDoc: $capturedMediaDoc)
                case .alerts:
                    Alerts(navigationPath: $navigationPath, alertData: $alertData, tappedObjectId: $tappedObjectId, medias: $medias, selectedObject: $selectedObject, selectedPriority: $selectedPriority, selectedType: $selectedType, selectedObjectId: $selectedObjectId, selectedPriorities: $selectedPriorities, selectedTypes: $selectedTypes, selectedObjectIds: $selectedObjectIds, tappedTaskId: $tappedTaskId)
                case.alertsfilters:
                    AlertsFilters(alertData: $alertData, navigationPath: $navigationPath, selectedPriority: $selectedPriority, selectedType: $selectedType, selectedObjectId: $selectedObjectId, selectedPriorities: $selectedPriorities, selectedTypes: $selectedTypes, selectedObjectIds: $selectedObjectIds, dataResponseObjectAll: $dataResponseObjectAll)
                case.chat:
                    ChatViewNew(tappedObjectId: $tappedObjectId, chatViewModel: ChatViewModel(), authResponse: $authResponse, selectedFile: $selectedFile, selectedFileName: $selectedFileName, navigationPath: $navigationPath)
                case.openObjectCamera:
                    openObjectCamera(navigationPath: $navigationPath, capturedMediaDoc: $capturedMediaDoc)
                case.openObjectDrugAndDropDocument:
                    openObjectDrugAndDropDocument(navigationPath: $navigationPath, capturedMediaDoc: $capturedMediaDoc, tappedObjectId: $tappedObjectId, generatedPDFURL: $generatedPDFURL)
                case.createcheck:
                    createCheck(navigationPath: $navigationPath, tappedObjectId: $tappedObjectId, viewModel: createcheckviewModel, generatedPDFURL: $generatedPDFURL, capturedMediaDoc: $capturedMediaDoc)
                case.createcheckcamera:
                    CreateCheckCamera(navigationPath: $navigationPath, capturedMediaDoc: $capturedMediaDoc)
                case.druganddropcheck:
                    DrugAndDropCheck(navigationPath: $navigationPath, capturedMediaDoc: $capturedMediaDoc, generatedPDFURL: $generatedPDFURL)
                case.taskvew:
                    ObjectTaskView(viewModel: ObjectTaskViewModel(), navigationPath: $navigationPath, tappedTaskId: $tappedTaskId)

                }
                
                
            }
        }
        .accentColor(.black)
        .onAppear {
            DispatchQueue.main.async {
                syncUserData()
                // Вызов функции синхронизации при запуске
            }
            let downloader = KingfisherManager.shared.downloader
            downloader.sessionConfiguration.httpMaximumConnectionsPerHost = 3
            downloader.downloadTimeout = 15

        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkNotification)) { notification in
            guard let userInfo = notification.userInfo,
                  let type = userInfo["type"] as? String,
                  let id = userInfo["id"] as? String else { return }
            
            if type == "objects" {
                DispatchQueue.main.async {
                    self.tappedObjectId = id
                    self.navigationPath.append(Destination.mainview)
                    self.navigationPath.append(Destination.objectDetails)
                    
                    // Проверяем параметр openChat
                    if let openChat = userInfo["openChat"] as? String, openChat == "true" {
                        self.navigationPath.append(Destination.chat)
                    }
                }
            } else if type == "tasks" {
                self.tappedTaskId = id
                self.navigationPath.append(Destination.mainview)
                self.navigationPath.append(Destination.taskvew)
            }
        }
        .overlay {
            NetworkBanner()
        }
    }
    // Функция для проверки accessToken и обновления состояния аутентификации
    private func checkAccessToken() -> Bool {
        return AccessTokenHolder.shared.getAccessToken() != nil
    }
    func syncUserData() {
        print("Запуск синхронизации данных пользователя...")
        
        // Получаем сохранённый AuthenticationResponse
        guard let savedData = UserDefaults.standard.data(forKey: "authResponse") else {
            print("AuthenticationResponse не найден в UserDefaults")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            var savedAuthResponse = try decoder.decode(AuthenticationResponse.self, from: savedData)
            print("Декодирование сохранённого AuthenticationResponse успешно")

            // Запрос к API для обновления данных
            NetworkAccessor.shared.get("/users/sync") { (result: Result<SyncResponse, Error>, statusCode: Int?) in
                print("Ответ от /users/sync: статус код \(String(describing: statusCode))")
                
                switch result {
                case .success(let syncResponse):
                    print("Успешно получены данные от сервера: \(syncResponse)")
                    
                    // Обновляем поля
                    savedAuthResponse.user.isEmployee = syncResponse.user.isEmployee
                    savedAuthResponse.permissions = syncResponse.permissions
                    print("Обновление полей isEmployee и permissions завершено")
                    
                    print("\(savedAuthResponse.permissions)")
                    
                    // Сохраняем обновлённую модель
                    self.saveAuthenticationResponse(savedAuthResponse)
                    print("AuthenticationResponse успешно сохранён")
                    
                case .failure(let error):
                    print("Ошибка при получении данных от /users/sync: \(error.localizedDescription)")
                }
            }
            
        } catch {
            print("Ошибка при декодировании AuthenticationResponse: \(error.localizedDescription)")
        }
    }
    
    func saveAuthenticationResponse(_ authResponse: AuthenticationResponse) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(authResponse)
            UserDefaults.standard.set(data, forKey: "authResponse")
            print("AuthenticationResponse успешно сохранён в UserDefaults \(data)")
        } catch {
            print("Ошибка при сохранении AuthenticationResponse: \(error.localizedDescription)")
        }
    }

    // Структура для синхронизации данных
    struct SyncResponse: Decodable {
        var user: FullUserResponse
        var permissions: [String]
    }
}

class AppStartupManager {
    
    static func handleFirstLaunch() {
        let hasLaunchedBeforeKey = "hasLaunchedBefore"
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: hasLaunchedBeforeKey) {
            // Это первый запуск приложения после установки — очищаем Keychain
            AccessTokenHolder.shared.clearAccessToken()
            
            // Устанавливаем флаг, чтобы не выполнять это при каждом запуске
            userDefaults.set(true, forKey: hasLaunchedBeforeKey)
            userDefaults.synchronize()
        }
    }
}
