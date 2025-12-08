//
//  objectDocuments.swift
//  stroymir
//
//  Created by Корнеев Александр on 27.06.2024.
//

import SwiftUI
import PDFKit
import Combine
import UIKit

struct ObjectDocuments: View {
    @Binding var tappedObjectId: String
    @State private var reports: [ReportDoc] = []       // Массив документов ReportDoc
    @State private var selectedReport: ReportDoc?
    @Binding var navigationPath: NavigationPath
    @Binding var selectedFile: String
    @Binding var selectedFileName: String
    @State var loadingPdf: Bool = true
    @State var showAddReportBottomSheet = false
    
    @State private var currentPage: Int = 0
    @State private var isLoading: Bool = false
    @State private var hasMoreData: Bool = true
    @Binding var authResponse: AuthenticationResponse?
    @Binding var selectedObject: ObjectResponse
    
    var body: some View {
        ZStack{
            VStack {
                if loadingPdf {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.top, 32)
                    
                } else if reports.isEmpty || reports == [] {
                    ZStack{
                        VStack {
                            
                            Image("visual-empty")
                                .resizable()
                                .frame(width: 140, height: 140)
                            
                            Text("Список пуст. Пока что здесь ничего нет")
                                .font(Fonts.Font_Headline2)
                        }
                        
                        if authResponse?.permissions.contains("WRITE_DOCUMENTS") == true && selectedObject.status == "IN_PROGRESS" {
                            VStack {
                                Spacer()
                                Button(action: {
                                    showAddReportBottomSheet = true
                                }, label: {
                                    HStack {
                                        Text("Добавить документ")
                                            .foregroundColor(Color.white)
                                            .font(Fonts.Font_Headline2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Colors.orange)
                                    .cornerRadius(16)
                                    .padding(.horizontal, 16)
                                })
                                .ignoresSafeArea() // Кнопка остаётся поверх всего
                            }
                        }
                    }
                } else {
                    ZStack {
                        VStack {
                            ScrollView {
                                // Элементы списка
                                ForEach(reports, id: \.documentId) { report in
                                    Button(action: {
                                        selectedFile = report.downloadUrl
                                        selectedFileName = report.title
                                        navigationPath.append(Destination.pdfview)
                                        print(selectedFile)
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Text(report.title)
                                                        .font(Fonts.Font_Headline2)
                                                        .foregroundColor(Color.black)
                                                    Spacer()
                                                }
                                                
                                                HStack {
                                                    Text("от \(createDateTime(timestamp: report.created))")
                                                        .font(Fonts.Font_Callout)
                                                        .foregroundColor(Colors.boldGray)
                                                    Spacer()
                                                }
                                                .padding(.top, -6)
                                                
                                                HStack {
                                                    if report.paymentInfo.status != nil {
                                                        if report.paymentInfo.status == "NOT_PAYED" {
                                                            
                                                            if report.payedByCash ?? true {
                                                                Image("payments_24_red")
                                                                    .resizable()
                                                                    .frame(width: 16, height: 16)
                                                            } else {
                                                                Image("credit_card_24red")
                                                                    .resizable()
                                                                    .frame(width: 16, height: 16)
                                                            }
                                                            
                                                            Text("Не оплачено")
                                                                .font(Fonts.Font_Footnote)
                                                                .foregroundColor(Color.red)
                                                            
                                                            
                                                        } else if report.paymentInfo.status == "PAYED" {
                                                            
                                                            if report.payedByCash ?? true {
                                                                Image("payments_24green")
                                                                    .resizable()
                                                                    .frame(width: 16, height: 16)
                                                            } else {
                                                                Image("credit_card_24green")
                                                                    .resizable()
                                                                    .frame(width: 16, height: 16)
                                                            }
                                                            
                                                            Text("Оплачено")
                                                                .font(Fonts.Font_Footnote)
                                                                .foregroundColor(Color.green)
                                                            
                                                        } else if report.paymentInfo.status == "RECEIVED" {
                                                            
//                                                            if retrieveIsEmployee() {
//                                                                
//                                                                if report.payedByCash ?? true {
//                                                                Image("payments_24green")
//                                                                    .resizable()
//                                                                    .frame(width: 16, height: 16)
//                                                                } else {
//                                                                    Image("credit_card_24green")
//                                                                        .resizable()
//                                                                        .frame(width: 16, height: 16)
//                                                                }
//                                                                
//                                                                Text("Оплачено")
//                                                                    .font(Fonts.Font_Footnote)
//                                                                    .foregroundColor(Color.red)
//                                                            } else {
                                                                if report.payedByCash ?? true {
                                                                Image("payments_24green")
                                                                    .resizable()
                                                                    .frame(width: 16, height: 16)
                                                                } else {
                                                                    Image("credit_card_24green")
                                                                        .resizable()
                                                                        .frame(width: 16, height: 16)
                                                                }
                                                                
                                                                Text("Получено")
                                                                    .font(Fonts.Font_Footnote)
                                                                    .foregroundColor(Color.green)
//                                                            }
                                                        } else if report.paymentInfo.status == "REGISTTERED" {
                                                            
//                                                            if retrieveIsEmployee() {
//                                                                if report.payedByCash ?? true {
//                                                                Image("payments_24green")
//                                                                    .resizable()
//                                                                    .frame(width: 16, height: 16)
//                                                                } else {
//                                                                    Image("credit_card_24green")
//                                                                        .resizable()
//                                                                        .frame(width: 16, height: 16)
//                                                                }
//                                                                
//                                                                Text("Оплачено")
//                                                                    .font(Fonts.Font_Footnote)
//                                                                    .foregroundColor(Color.red)
//                                                            } else {
                                                                if report.payedByCash ?? true {
                                                                Image("payments_24green")
                                                                    .resizable()
                                                                    .frame(width: 16, height: 16)
                                                                } else {
                                                                    Image("credit_card_24green")
                                                                        .resizable()
                                                                        .frame(width: 16, height: 16)
                                                                }
                                                                
                                                                Text("В Каассе")
                                                                    .font(Fonts.Font_Footnote)
                                                                    .foregroundColor(Color.green)
//                                                            }
                                                            
                                                        }
                                                    } else {
                                                        if report.isVerified ?? true {
                                                            Text("Подтвержден")
                                                                .font(Fonts.Font_Footnote)
                                                                .foregroundColor(Color.green)
                                                        } else {
                                                            Text("Не подтвержден")
                                                                .font(Fonts.Font_Footnote)
                                                                .foregroundColor(Color.red)
                                                        }
                                                    }
                                                    Spacer()
                                                }
                                                .padding(.top, -2)
                                                .padding(.bottom, 16)
                                            }
                                            
                                            Image("arrow_forward")
                                                .padding(.bottom, 16)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .listRowSeparator(.hidden)
                                    .frame(height: 80)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Colors.lightGrayOverlay, lineWidth: 1)
                                    )
                                }
                                if isLoading {
                                    ProgressView() // Индикатор загрузки
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else if hasMoreData {
                                    // Невидимый элемент, добавляемый в конец списка для отступа
                                    Color.clear
                                        .frame(height: 10)
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .onAppear {
                                            loadMoreDataIfNeeded()
                                        }
                                }
                                Spacer()
                                    .frame(height: 60)
                            }
                            .scrollIndicators(.hidden)
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                            .refreshable {
                                if !getIsLoading() {
                                    setIsLoading(true)
                                    print("Перед загрузкой: isLoading = \(getIsLoading())")
                                    Task {
                                        do {
                                            let newReports = try await loadDoc(for: tappedObjectId, page: 0) // Всегда page=0 при обновлении
                                            withAnimation {
                                                reports = newReports // Полная замена данных
                                            }
                                            hasMoreData = !newReports.isEmpty
                                            print("Успешно загружено \(newReports.count) записей")
                                        } catch {
                                            print("Ошибка обновления данных: \(error.localizedDescription)")
                                            // Сбросить hasMoreData в true, чтобы разрешить повторные попытки
                                            hasMoreData = true
                                        }
                                        setIsLoading(false)
                                    }
                                } else {
                                    print("Загрузка уже идет, пропускаем обновление")
                                }
                            }
                        }


                        VStack {
                            Spacer()
                            if authResponse?.permissions.contains("WRITE_DOCUMENTS") == true && selectedObject.status == "IN_PROGRESS" {
                                Button(action: {
                                    showAddReportBottomSheet = true
                                }, label: {
                                    HStack {
                                        Text("Добавить документ")
                                            .foregroundColor(Color.white)
                                            .font(Fonts.Font_Headline2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Colors.orange)
                                    .cornerRadius(16)
                                    .padding(.horizontal, 16)
                                })
                                .ignoresSafeArea() // Кнопка остаётся поверх всего
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    do {
                        let initialReports = try await loadDoc(for: tappedObjectId)
                        reports = initialReports
                        currentPage = 0
                        hasMoreData = !initialReports.isEmpty
                        loadingPdf = false
                    } catch {
                        print("Error loading initial data: \(error.localizedDescription)")
                        // Обработка ошибки, например, показ сообщения пользователю
                    }
                }
            }
            .sheet(isPresented: $showAddReportBottomSheet){
                VStack {
                    HStack{
                        Text("Способ загрузки")
                            .font(Font.custom("Roboto", size: 20).weight(.semibold))
                            .padding(.top, 24)
                        
                        Spacer()
                    }
                    
                    Button(action: {
                        showAddReportBottomSheet = false
                        navigationPath.append(Destination.camerastructdoc)
                    }, label: {
                        HStack{
                            Image("picture_as_pdf")
                            Text("Отснять")
                                .foregroundColor(Colors.orange)
                            Spacer()
                        }
                    })
                    .padding(.top, 16)
                    
                    Button(action: {
                        navigationPath.append(Destination.createdocumentview)
                        showAddReportBottomSheet = false
                    }, label: {
                        HStack{
                            Image("folder_open")
                            Text("Выбрать файл")
                                .foregroundColor(Colors.textFieldOverlayGray)
                            Spacer()
                        }
                    })
                    .padding(.top, 8)
                    
                    Spacer()
                    
                }
                .presentationDetents([.medium, .height(180)])
                .padding(.horizontal, 16)
            }
        }
    }

    private let loadingQueue = DispatchQueue(label: "loadingQueue")

    func setIsLoading(_ value: Bool) {
        loadingQueue.sync {
            isLoading = value
        }
    }

    func getIsLoading() -> Bool {
        return loadingQueue.sync {
            return isLoading
        }
    }
    
    // Функция для форматирования даты
    func createDateTime(timestamp: Int64) -> String {
        let unixTimeSeconds = TimeInterval(timestamp / 1000)
        let date = Date(timeIntervalSince1970: unixTimeSeconds)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "d MMM yyyy'г.'"
        return dateFormatter.string(from: date)
    }
    
    func retrieveIsEmployee() -> Bool {
        return UserDefaults.standard.bool(forKey: "isEmployee")
    }

    // Функция загрузки данных
    private func loadDoc(for objectId: String, page: Int = 0) async throws -> [ReportDoc] {
        print("⏳ Starting loadDoc for objectID: \(objectId), page: \(page)")
        isLoading = true
        defer {
            isLoading = false
            print("🔚 loadDoc completed. isLoading set to false")
        }

        // 1. Parse base URL
        print("🔧 Step 1: Parsing baseURL: \(AppConfig.baseURL)")
        guard let baseComponents = URLComponents(string: AppConfig.baseURL) else {
            print("❌ ERROR: Invalid baseURL components")
            throw URLError(.badURL)
        }

        // 2. Build final URL
        print("🔧 Step 2: Building final URL components")
        var urlComponents = URLComponents()
        urlComponents.scheme = baseComponents.scheme
        urlComponents.host = baseComponents.host
        print("ℹ️ Scheme: \(baseComponents.scheme ?? "nil"), Host: \(baseComponents.host ?? "nil")")

        // 3. Combine paths
        let basePath = baseComponents.path
        let endpoint = "objects/documents"
        urlComponents.path = basePath + endpoint
        print("🔗 Combined path: \(urlComponents.path)")

        // 4. Add query parameters
//        print("🔧 Step 4: Adding query parameters")
//        guard let encodedObjectId = objectId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
//            print("❌ ERROR: Failed to encode objectID: \(objectId)")
//            throw URLError(.badURL)
//        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "objectId", value: tappedObjectId),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "10")
        ]
        print("🔍 Query Items: \(urlComponents.queryItems?.debugDescription ?? "nil")")

        // 5. Validate final URL
        print("🔧 Step 5: Validating final URL")
        guard let url = urlComponents.url else {
            print("❌ ERROR: Invalid URL components:")
            print("Components dump: \(urlComponents)")
            throw URLError(.badURL)
        }
        print("✅ Final URL: \(url.absoluteString)")

        return try await withCheckedThrowingContinuation { continuation in
            print("🌐 Starting network request...")
            NetworkAccessor.shared.get(url.absoluteString) { (result: Result<MainResponseDoc, Error>, statusCode: Int?) in
                print("📡 Received response. Status code: \(statusCode ?? -1)")
                
                switch result {
                case .success(let mainResponse):
                    print("✔️ Success. Received \(mainResponse.content.count) documents")
                    print("📄 Response data sample: \(mainResponse.content.prefix(2))")
                    continuation.resume(with: .success(mainResponse.content))
                    
                case .failure(let error):
                    print("❌ NETWORK ERROR:")
                    print("Error type: \(type(of: error))")
                    print("Error description: \(error.localizedDescription)")
                    if let urlError = error as? URLError {
                        print("URL Error Code: \(urlError.code)")
                    }
                    continuation.resume(with: .failure(error))
                }
            }
        }
    }
    
    private func loadMoreData() {
        guard hasMoreData else { return }
        isLoading = true
        Task {
            do {
                let nextPage = currentPage + 1
                let newReports = try await Task.detached {
                            try await self.loadDoc(for: tappedObjectId, page: nextPage)
                        }.value
                if !newReports.isEmpty {
                    reports.append(contentsOf: newReports)
                    currentPage = nextPage
                } else {
                    hasMoreData = false
                }
            } catch {
                print("Error loading more data: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    func loadMoreDataIfNeeded() {
        guard !isLoading, hasMoreData else { return }
        loadMoreData()
    }
}

