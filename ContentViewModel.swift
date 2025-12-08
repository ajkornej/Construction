//
//  ContentViewModel.swift
//  Construction
//
//  Created by Корнеев Александр on 08.12.2025.
//

import SwiftUI
import Combine


final class ContentViewModel: ObservableObject {
    
    // MARK: - Navigation State
    
    @Published var navigationPath = NavigationPath()
    
    // MARK: - Authentication State
    
    @Published var isAuthenticated: Bool = false
    @Published var authResponse: AuthenticationResponse?
    
    // MARK: - Object State
    
    @Published var tappedObjectId: String = ""
    @Published var tappedAddress: String = ""
    @Published var selectedObject: ObjectResponse = ObjectResponse(
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
        reportExpired: false,
        problemStatus: false,
        cashInfo: nil,
        fullAddress: "",
        imageUrl: nil
    )
    @Published var dataResponseObjectAll: [ObjectResponse] = []
    
    // MARK: - Task State
    
    @Published var tappedTaskId: String = ""
    
    // MARK: - Media State
    
    @Published var medias: [Media] = []
    @Published var capturedImages: [UIImage] = []
    @Published var capturedVideos: [URL] = []
    @Published var capturedMedia: [CapturedMedia] = []
    @Published var capturedMediaDoc: [CapturedMediaDocument] = []
    
    // MARK: - File State
    
    @Published var selectedFile: String = ""
    @Published var selectedFileName: String = ""
    @Published var generatedPDFURL: URL?
    
    // MARK: - UI State
    
    @Published var showingBottomSheet: Bool = false
    @Published var isShowingObjectDetails: Bool = false
    @Published var zoomLevel: CGFloat = 10.0
    @Published var onlyPhoto: Bool = false
    @Published var needsRefresh: Bool = false
    
    // MARK: - Alerts State
    
    @Published var alertData: [AlertResponse] = []
    @Published var selectedPriority: String = ""
    @Published var selectedType: String = ""
    @Published var selectedObjectId: String = ""
    @Published var selectedPriorities: [String] = []
    @Published var selectedTypes: [String] = []
    @Published var selectedObjectIds: [String] = []
    
    // MARK: - Deprecated (для совместимости)
    
    @Published var allUserNames: String = ""
    
    // MARK: - Initialization
    
    init() {
        AppStartupManager.handleFirstLaunch()
        isAuthenticated = checkAccessToken()
    }
    
    // MARK: - Public Methods
    
    // Проверяет наличие токена доступа
    func checkAccessToken() -> Bool {
        return AccessTokenHolder.shared.getAccessToken() != nil
    }
    
    // Синхронизирует данные пользователя с сервером
    func syncUserData() {
        print("Запуск синхронизации данных пользователя...")
        
        guard let savedData = UserDefaults.standard.data(forKey: UserDefaultsKeys.authResponse) else {
            print("AuthenticationResponse не найден в UserDefaults")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            var savedAuthResponse = try decoder.decode(AuthenticationResponse.self, from: savedData)
            print("Декодирование сохранённого AuthenticationResponse успешно")
            
            NetworkAccessor.shared.get("/users/sync") { [weak self] (result: Result<SyncResponse, Error>, statusCode: Int?) in
                print("Ответ от /users/sync: статус код \(String(describing: statusCode))")
                
                switch result {
                case .success(let syncResponse):
                    print("Успешно получены данные от сервера: \(syncResponse)")
                    
                    savedAuthResponse.user.isEmployee = syncResponse.user.isEmployee
                    savedAuthResponse.permissions = syncResponse.permissions
                    print("Обновление полей isEmployee и permissions завершено")
                    print("\(savedAuthResponse.permissions)")
                    
                    self?.saveAuthenticationResponse(savedAuthResponse)
                    print("AuthenticationResponse успешно сохранён")
                    
                case .failure(let error):
                    print("Ошибка при получении данных от /users/sync: \(error.localizedDescription)")
                }
            }
            
        } catch {
            print("Ошибка при декодировании AuthenticationResponse: \(error.localizedDescription)")
        }
    }
    
    // Обрабатывает deep link навигацию
    func handleDeepLink(type: String, id: String, openChat: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if type == "objects" {
                self.tappedObjectId = id
                self.navigationPath.append(Destination.mainview)
                self.navigationPath.append(Destination.objectDetails)
                
                if openChat {
                    self.navigationPath.append(Destination.chat)
                }
            } else if type == "tasks" {
                self.tappedTaskId = id
                self.navigationPath.append(Destination.mainview)
                self.navigationPath.append(Destination.taskvew)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func saveAuthenticationResponse(_ authResponse: AuthenticationResponse) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(authResponse)
            UserDefaults.standard.set(data, forKey: UserDefaultsKeys.authResponse)
            print("AuthenticationResponse успешно сохранён в UserDefaults \(data)")
        } catch {
            print("Ошибка при сохранении AuthenticationResponse: \(error.localizedDescription)")
        }
    }
}

