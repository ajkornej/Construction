//
//  ObjectChecksViewModel.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 28.01.2025.
//

import SwiftUI

@MainActor
final class ObjectChecksViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    @Published var isLoading: Bool = false
    @Published var hasMoreData: Bool = true
    @Published var loadingPdf: Bool = true
    @Published var showAddCheckBottomSheet = false
    @Published var tickets: [GetTicketsResponse.Ticket] = []
    @Published var authResponse: AuthenticationResponse?
    @Published var nomenclaturesStruct: [NomenclaturesStruct] = []
    
    @Published var selectedNomenclaturesStruct: String? = nil
    
    @Published var isNomenklatureEmpty: Bool = true
    @Published var generatedPDFURL: URL?
    
    private let service: ObjectChecksService = .init()
    private let tappedObjectId: String
    
    init(tappedObjectId: String) {
        self.tappedObjectId = tappedObjectId
        
    }
    
    func trigger(_ input: Input) async {
        switch input {
        case .onAppear:
            await viewWillAppear()
        }
    }
    
    func createDateTime(timestamp: String) -> String {
        var endDate = ""
        if let unixTimeMillis = Double(timestamp) {
            let unixTimeSeconds = unixTimeMillis / 1000
            let date = Date(timeIntervalSince1970: unixTimeSeconds)
            let dateFormatter = DateFormatter()
            let timezone = TimeZone.current.abbreviation() ?? "CET"
            dateFormatter.timeZone = TimeZone(abbreviation: timezone)
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateFormat = "d MMM yyyy'г.'"
            endDate = dateFormatter.string(from: date)
        }
        return endDate
    }
    
    func getOnomenclatures(completion: @escaping (Bool) -> Void) {
        NetworkAccessor.shared.get("/nomenclatures/all") { (result: Result<[NomenclaturesStruct], Error>, statusCode: Int?) in
            switch result {
            case .success(let data):
                Task { @MainActor in
                    self.nomenclaturesStruct = data
                }
                print("getOnomenclatures data\(data)")
                // Проверяем статус-код
                if let statusCode = statusCode {
                    print("ебаный статус код \(statusCode)")
                    if statusCode == 403 {
                        print("Ошибка 403: Доступ запрещён.")
                        
                    } else {
                        print("Получен статус-код: \(statusCode)")
                    }
                }
                
                print("getObjectAll Success")
                print("nomenclaturesStruct \(self.nomenclaturesStruct)")
                
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    // Обновление данных при pull-to-refresh
    @MainActor
    func refreshChecks() async {
        tickets = [] // Очищаем текущие данные
        currentPage = 0
        hasMoreData = true
        isLoading = true
        await loadCheck()
        isLoading = false
    }
    
    // Загрузка дополнительных данных при достижении конца списка
    @MainActor
    func loadMoreChecks() async {
        if !isLoading && hasMoreData {
            isLoading = true
            await loadCheck(page: currentPage + 1)
            isLoading = false
        }
    }
}

private extension ObjectChecksViewModel {
    func viewWillAppear() async {
        await loadCheck()
        Task { @MainActor in
            authResponse = loadAuthenticationResponse()
        }
    }
    
    func loadCheck(page: Int = 0) async {
        do {
            if tickets.isEmpty, page == 0 { isLoading = true }
            let response = try await service.getTickets(objectId: tappedObjectId, page: String(page), nomenclatureId: selectedNomenclaturesStruct)
            handleResponse(response, isRefreshing: page == 0)
            currentPage = page
            isLoading = false
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @MainActor
    func handleResponse(_ response: GetTicketsResponse, isRefreshing: Bool) {
        if isRefreshing {
            tickets = response.page.content
        } else {
            tickets.append(contentsOf: response.page.content)
        }
        hasMoreData = response.page.content.count > 0 // Предполагаем, что есть еще данные, если пришли элементы
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
}

enum Input {
    case onAppear
}

struct NomenclaturesStruct: Decodable, Equatable {
    let nomenclatureId: String
    let title: String
}
