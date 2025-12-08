//
//  objectDetails.swift
//  stroymir
//
//  Created by Корнеев Александр on 19.05.2024.
//

import SwiftUI
import KeychainSwift
import AVKit
import Kingfisher

struct objectDetails: View {
    @Binding var navigationPath: NavigationPath
    @Binding var tappedObjectId: String
    @State private var selectedTap: Int = 0
    @State private var sheetShown = false
    @Binding var medias: [Media]
    @Binding var selectedFile: String
    @Binding var selectedFileName: String
    @Binding var selectedObject: ObjectResponse
    @Binding var showingBottomSheet: Bool
    
    @Binding var isShowingObjectDetails: Bool
    @Binding var capturedMedia: [CapturedMedia]
    
    @State private var authResponse: AuthenticationResponse?
    
    @Binding var dataResponseObjectAll: [ObjectResponse]
    
    @Binding var needsRefresh: Bool
    
    @State private var unrreadCount: Int = 0
    
    @State var isError: Bool = false
    
    @State var frikTapsAvaiple: Int = 0
    
    @Binding var tappedTaskId: String
    
    
//    private let objectCheckAssembly = ObjectChecksAssembly()
    
    var body: some View {
        VStack{
            VStack{
                if selectedObject.status == "IN_PROGRESS" {
                    
                    if selectedObject.problemStatus ?? false {
//                        if retrieveIsEmployee() {
//                        HStack {
//                            Image("info_24blue")
//                            
//                            Text("В работе")
//                                .font(Fonts.Font_Callout)
//                                .foregroundColor(Color.blue)
//                            Spacer()
//                        }
//                            }
//                        } else {
                           
                        HStack {
                            Image("error_FILL0_red")

                            Text("Проблемный объект")
                                .font(Fonts.Font_Callout)
                                .foregroundColor(Color.red)
                            Spacer()
                        }
//                        }
                    } else if selectedObject.reportExpired {
//                        if retrieveIsEmployee() {
//                        HStack {
//                            Image("info_24blue")
//                            
//                            Text("В работе")
//                                .font(Fonts.Font_Callout)
//                                .foregroundColor(Color.blue)
//                            Spacer()
//                        }
//
//                        } else {
                        HStack {
                           Image("error_FILL0_red")

                           Text("Отчёт просрочен")
                               .font(Fonts.Font_Callout)
                               .foregroundColor(Color.red)
                           Spacer()
                       }
//                        }
                    } else {
                        // Если нет просроченных отчётов и не требуется подписание
                        HStack {
                            Image("info_24blue")
                            
                            Text("В работе")
                                .font(Fonts.Font_Callout)
                                .foregroundColor(Color.blue)
                            Spacer()
                        }
                    }
                } else if selectedObject.status == "NEW" {
                    // Статус "Новый"
                    HStack {
                        Image("error_FILL0_green")
                        
                        Text("Новый")
                            .font(Fonts.Font_Callout)
                            .foregroundColor(Color.green)
                        Spacer()
                    }
                } else if selectedObject.status == "ARCHIVE" {
                    // Статус "В архиве"
                    HStack {
                        Image("error_FILL0_gray")
                        
                        Text("В архиве")
                            .font(Fonts.Font_Callout)
                            .foregroundColor(Colors.textFieldOverlayGray)
                        Spacer()
                    }
                } else if selectedObject.status == "DONE" {
                    // Статус "Новый"
                    HStack {
                        Image("info_24green")
                        
                        Text("Сдан")
                            .font(Fonts.Font_Footnote)
                            .foregroundColor(Color.green)
                        Spacer()
                    }
                } else if selectedObject.status == "TERMINATED" {
                    // Статус "Новый"
                    HStack {
                        Rectangle()
                            .frame(width: 12, height: 12)
                            .foregroundColor(.red)
                            .cornerRadius(100)
                        
                        Text("Расторгнут")
                            .font(Fonts.Font_Footnote)
                            .foregroundColor(Color.red)
                        
                        Spacer()
                    }
                }
                
                HStack{
                    Image("location_on")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text(selectedObject.fullAddress)
                        .font(Fonts.Font_Callout)
                    Spacer()
                }
                .padding(.top, 4)
                
                if selectedObject.startDate != nil {
                    HStack{
                    Image("calendar_month")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text(createDateTime(timestamp: String(selectedObject.startDate ?? 0)))
                        .font(Fonts.Font_Callout)
                    
                    if (selectedObject.endDate != nil) {
                        Text("—  \(createDateTime(timestamp: String(selectedObject.endDate!)))")
                            .font(Fonts.Font_Callout)
                        
                    }
                    Spacer()
                }
                    .padding(.top, 4)
            }
                
                if /*authResponse?.user.isEmployee == true &&*/ !selectedObject.comment.isEmpty  {
                    HStack{
                        Image("notes_24")
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        Text(selectedObject.comment)
                            .font(Fonts.Font_Callout)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
             
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
        if isError {
            
            Spacer()
            
            Text("Ошибка. Что-то пошло не так...")
            
            Spacer()
            
        }
            
            if selectedObject.status == "NEW" {
                
                VStack{
                    Spacer()
                    Image("close_object")
                        .resizable()
                        .frame(width: 140, height: 140)
                        .padding(.top, 200)
                    
                    Text("Объект не открыт")
                        .font(Fonts.Font_Headline2)
                    
                    Text("Информация недоступна")
                        .font(Fonts.Font_Callout)
                    
                    Spacer()
                    
                    if authResponse?.permissions.contains("OPEN_OBJECTS") == true {
                        VStack {
                            Spacer()
                            Button(action: {
                                navigationPath.append(Destination.openobject)
                            }) {
                                Text("Открыть объект")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Colors.orange)
                                    .cornerRadius(16)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                
            } else {
                // taps
                HStack {
                    if authResponse?.permissions.contains("READ_REPORTS") == true /*|| authResponse?.user.isEmployee == false*/ {
                        Button(action: {
                            self.selectedTap = 0
                        }) {
                            Text("Отчёты")
                                .font(Fonts.Font_Headline2)
                                .foregroundColor(selectedTap == 0 ? .black : .gray)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    if authResponse?.permissions.contains("READ_DOCUMENTS") == true /*|| authResponse?.user.isEmployee == false*/ {
                        Button(action: {
                            self.selectedTap = 1
                        }) {
                            if frikTapsAvaiple > 3 {
                                Text("Док-ты")
                                    .font(Fonts.Font_Headline2)
                                    .foregroundColor(selectedTap == 1 ? .black : .gray)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Документы")
                                    .font(Fonts.Font_Headline2)
                                    .foregroundColor(selectedTap == 1 ? .black : .gray)
                                    .frame(maxWidth: .infinity)
                            }
                            
                        }
                    }
                    
                    if authResponse?.permissions.contains("READ_TICKETS") == true /*|| authResponse?.user.isEmployee == false*/ {
                        Button(action: {
                            self.selectedTap = 2
                        }) {
                            Text("Чеки")
                                .font(Fonts.Font_Headline2)
                                .foregroundColor(selectedTap == 2 ? .black : .gray)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    if authResponse?.permissions.contains("READ_TASKS") == true {
                        Button(action: {
                            self.selectedTap = 3
                        }) {
                            Text("Задачи")
                                .font(Fonts.Font_Headline2)
                                .foregroundColor(selectedTap == 3 ? .black : .gray)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .overlay(
                    GeometryReader { geometry in
                        // Определяем доступные вкладки
                        let availableTabs = [
                            (authResponse?.permissions.contains("READ_REPORTS") == true ) ? 0 : nil,
                            (authResponse?.permissions.contains("READ_DOCUMENTS") == true ) ? 1 : nil,
                            (authResponse?.permissions.contains("READ_TICKETS") == true ) ? 2 : nil,
                            (authResponse?.permissions.contains("READ_TASKS") == true ) ? 3 : nil
                        ].compactMap { $0 } // Убираем nil, оставляем только индексы присутствующих вкладок
                        
                        let numberOfTabs = availableTabs.count // Реальное количество вкладок
                        let tabWidth = geometry.size.width / CGFloat(numberOfTabs) // Ширина одной вкладки
                        let currentIndex = availableTabs.firstIndex(of: selectedTap) ?? 0 // Индекс текущей вкладки
                        
                        Rectangle()
                            .frame(width: tabWidth, height: 2)
                            .offset(x: CGFloat(currentIndex) * tabWidth, y: geometry.size.height + 16)
                            .foregroundColor(Colors.orange)
                    }
                )
                .padding(.top, 16)
                
                if selectedTap == 0 {
                    objectPhotos(tappedObjectId: $tappedObjectId, medias: $medias, navigationPath: $navigationPath, authResponse: $authResponse, selectedObject: $selectedObject)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.width < -50 {
                                        withAnimation {
                                            self.selectedTap = min(self.selectedTap + 1, 1)
                                        }
                                    } else if value.translation.width > 50 {
                                        withAnimation {
                                            self.selectedTap = max(self.selectedTap - 1, 0)
                                        }
                                    }
                                }
                        )

                } else if selectedTap == 1 {
                    ObjectDocuments(tappedObjectId: $tappedObjectId, navigationPath: $navigationPath, selectedFile: $selectedFile, selectedFileName: $selectedFileName, authResponse: $authResponse, selectedObject: $selectedObject)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.width < -50 {
                                        withAnimation {
                                            self.selectedTap = min(self.selectedTap + 1, 1)
                                        }
                                    } else if value.translation.width > 50 {
                                        withAnimation {
                                            self.selectedTap = max(self.selectedTap - 1, 0)
                                        }
                                    }
                                }
                        )
                } else if selectedTap == 2 {
                    ObjectChecksView(navigationPath: $navigationPath, selectedFile: $selectedFile, viewModel: ObjectChecksViewModel(tappedObjectId: tappedObjectId), selectedObject: $selectedObject)
                } else if selectedTap == 3 {
                    ObjectDetailTaskView(tappedObjectId: $tappedObjectId, navigationPath: $navigationPath, tappedTaskId: $tappedTaskId)
                }
            }
            
            Spacer()
        }
        .onAppear{
           
            capturedMedia = []
            self.authResponse = loadAuthenticationResponse()
            print("selectedObject.objectId objectDitailes \(selectedObject.objectId)")
            print(authResponse?.permissions ?? "nill")
            
            getObjectCurrent { success in
                if success {
                    print("getObjectCurrent success")
                } else {
                    print("getObjectCurrent failed")
                }
            }
            
            getUnreadCount(for: tappedObjectId) { unreadCount in
                if let count = unreadCount {
                    print("Непрочитанных сообщений: \(count)")
                    unrreadCount = count
                } else {
                    print("Не удалось получить количество непрочитанных сообщений.")
                }
            }
            
            updateAvailableTabs()

        }
        .navigationTitle(("ИД \(String(tappedObjectId))"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem() {
                Button(action: {
                    sheetShown = true
                }, label: {
                    Image("persons")
                        .padding(.top, -2)
                })
                .sheet(isPresented: $sheetShown) {
                    VStack {
                        HStack{
                            Text("Участники объекта")
                                .font(Font.custom("Roboto", size: 20).weight(.semibold))
                                .padding(.top, 24)
                                .padding(.horizontal, 16)
                            Spacer()
                        }
                        
                        ScrollView {
                            let items = selectedObject.users
                            
                            ForEach(items.indices, id: \.self) { index in
                                let currentItem = items[index]
                                
                                UserRow(currentItem: currentItem)
                                    .listRowSeparator(.hidden)
                                    .padding(.top, 16)
                                    .padding(.horizontal, 16)
                                   
                            }
                        }
                        
                        Spacer()
                        
                    }
                    .presentationDetents([.height(calculateSheetHeight())])
                }
            }
            
            ToolbarItem() {
                if selectedObject.status == "NEW" || selectedObject.status == "IN_PROGRESS" {
                    Button(action: {
                        navigationPath.append(Destination.chat)
                    }, label: {
                        if unrreadCount == 0 {
                            Image("chat_FILL0")
                                .padding(.top, -2)
                        } else {
                            ZStack{
                                Image("chat_FILL0")
                                    .padding(.top, -2)
                                
                                Circle()
                                    .foregroundColor(.red)
                                    .frame(width: 16, height: 16)
                                    .padding(.top, -16)
                                    .padding(.trailing, 16)
                            
                                if unrreadCount > 9 {
                                    Text("9+")
                                        .foregroundColor(.white)
                                        .padding(.top, -12)
                                        .padding(.trailing, 16)
                                        .font(Font.custom("Roboto-Medium", size: 9))
                                } else {
                                    
                                    Text("\(unrreadCount)")
                                        .foregroundColor(.white)
                                        .padding(.top, -12)
                                        .padding(.trailing, 16)
                                        .font(Font.custom("Roboto-Medium", size: 9))
                                }
                                    
                            }
                        }
                    })
                }
            }
        }
    }
    
    private func updateAvailableTabs() {
            let availableTabs = [
                (authResponse?.permissions.contains("READ_REPORTS") == true) ? 0 : nil,
                (authResponse?.permissions.contains("READ_DOCUMENTS") == true) ? 1 : nil,
                (authResponse?.permissions.contains("READ_TICKETS") == true) ? 2 : nil,
                (authResponse?.permissions.contains("READ_TASKS") == true) ? 3 : nil
            ].compactMap { $0 }
            
            frikTapsAvaiple = availableTabs.count
        print("frikTapsAvaiple \(frikTapsAvaiple)")
        }
    
    private func calculateSheetHeight() -> CGFloat {
        let rowHeight: CGFloat = 80
        let userCount = selectedObject.users.count
        let headerHeight: CGFloat = 40
        let listTopPadding: CGFloat = 24 // Отступ списка сверху
        let totalRowsHeight = CGFloat(userCount) * rowHeight
        let totalHeight = headerHeight + listTopPadding + totalRowsHeight
        
        print("userCount\(userCount)")
        // Ограничиваем максимальной высотой (например, 80% экрана)
        return min(totalHeight, UIScreen.main.bounds.height * 0.8)
    }
    
    func createDateTime(timestamp: String) -> String {
        var endDate = ""
        
        if let unixTimeMillis = Double(timestamp) {
            // Конвертируем временную метку в секунды
            let unixTimeSeconds = unixTimeMillis / 1000
            let date = Date(timeIntervalSince1970: unixTimeSeconds)
            let dateFormatter = DateFormatter()
            let timezone = TimeZone.current.abbreviation() ?? "CET"
            dateFormatter.timeZone = TimeZone(abbreviation: timezone)
            dateFormatter.locale = NSLocale.current
            
            // Форматируем день
            dateFormatter.dateFormat = "d"
            let day = dateFormatter.string(from: date)
            
            // Форматируем и сокращаем месяц
            dateFormatter.dateFormat = "MMM"
            let month = dateFormatter.string(from: date)
            
            // Форматируем год
            dateFormatter.dateFormat = "yyyy"
            let year = dateFormatter.string(from: date)
            
            // Получаем текущий год
            let currentYear = Calendar.current.component(.year, from: Date())
            let currentYearString = String(currentYear)
            
            // Собираем строку в зависимости от совпадения года
            if year == currentYearString {
                endDate = "\(day) \(month)"
            } else {
                endDate = "\(day) \(month) \(year)г."
            }
        }
        
        return endDate
    }
    
    func retrieveIsEmployee() -> Bool {
        return UserDefaults.standard.bool(forKey: "isEmployee")
    }
    
    private func filteredEmployees() -> [UserResponse] {
        return selectedObject.users.filter { $0.isEmployee }
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
    
    func getObjectAll(completion: @escaping (Bool) -> Void) {
        NetworkAccessor.shared.get("/objects/all") { (result: Result<[ObjectResponse], Error>, statusCode: Int?) in
            switch result {
            case .success(let data):
                dataResponseObjectAll = data
               
                // Проверяем статус-код
                if let statusCode = statusCode {
                    print("ебаный статус код \(statusCode)")
                    if statusCode == 403 {
                        print("Ошибка 403: Доступ запрещён.")
                    } else if statusCode == 200 {
                        print("Получен статус-код: \(statusCode)")
                    } else {
                        print("Получен статус-код: \(statusCode)")
                        isError = true
                    }
                }
                print("getObjectAll Success")
            case .failure(let error):
                print("Error: \(error)")
               
                
            }
        }
    }
    
    func getObjectCurrent(completion: @escaping (Bool) -> Void) {
        NetworkAccessor.shared.get("/objects/\(tappedObjectId)") { (result: Result<ObjectWrapper, Error>, statusCode: Int?) in
            switch result {
            case .success(let wrapper):
                selectedObject = wrapper.object
                print("Object data:", wrapper.object)
                completion(true)
                
            case .failure(let error):
                print("Error: \(error)")
                completion(false)
            }
        }
    }
    
    func getUnreadCount(for objectId: String, completion: @escaping (Int?) -> Void) {
        // Создаем параметры запроса
        let queryParams = [
            URLQueryItem(name: "objectId", value: tappedObjectId)
        ]
        
        // Создаем URL с параметрами
        guard var urlComponents = URLComponents(string: "/chat/unreadCount") else {
            print("Invalid URL")
            completion(nil)
            return
        }
        urlComponents.queryItems = queryParams
        
        guard let url = urlComponents.url else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        // Выполняем запрос
        NetworkAccessor.shared.get(url.absoluteString) { (result: Result<Int, Error>, statusCode: Int?) in
            switch result {
            case .success(let unreadCount):
                // Проверяем статус-код
                if let statusCode = statusCode {
                    if statusCode == 403 {
                        print("Ошибка 403: Доступ запрещён.")
                        completion(nil)
                    } else {
                        print("Получен статус-код: \(statusCode)")
                        print("Количество непрочитанных сообщений: \(unreadCount)")
                        completion(unreadCount)
                    }
                } else {
                    print("Статус-код отсутствует")
                    completion(nil)
                }
            case .failure(let error):
                print("Ошибка запроса: \(error)")
                completion(nil)
            }
        }
    }
}


struct UserRow: View {
    var currentItem: UserResponse
    
    var body: some View {
        VStack{
            Button(action: {
                if let phone = currentItem.phone {
                    let cleanedPhoneNumber = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    let telephone = "tel://"
                    let formattedString = telephone + cleanedPhoneNumber
                    if let url = URL(string: formattedString) {
                        UIApplication.shared.open(url)
                    }
                }
            }) {
                
                HStack {
                    if currentItem.imageUrl != nil {
                        KFImage.url(URL(string: currentItem.imageUrl ?? ""))
                            .requestModifier { request in
                                if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                                        print("аватарка должна загрузиться")
                                   
                                } else {
                                    print("Access token not available")
                                }
                            }
                            .placeholder { progress in
                                ProgressView()
                            }
                            .resizable()
                            .frame(width: 48, height: 48)
                            .cornerRadius(100)
                            .overlay(RoundedRectangle(cornerRadius: 100).stroke(Colors.orange, lineWidth: 1))
                    
                    } else {
                        Image("profile_placeholder")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .cornerRadius(100)
                            .overlay(RoundedRectangle(cornerRadius: 100).stroke(Colors.orange, lineWidth: 1))
                    }
                    
                    VStack {
                        Text("\(currentItem.surname) \(currentItem.name) \(currentItem.patronymic)")
                            .font(Fonts.Font_Headline2)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        Text(currentItem.jobTitle?.lowercased() ?? "клиент")
                            .font(Fonts.Font_Callout)
                            .foregroundColor(Colors.textFieldOverlayGray)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .padding(.horizontal, 8)
                    
                    Spacer()
                    
                    Image("phone_in_talk")
                }
                .padding(.top, -8)
            }
            Divider() // Кастомный разделитель
                .background(Colors.textFieldOverlayGray)
                .padding(.horizontal, -16)
                .padding(.top, 8)
        }
        .onAppear{
            print("link \(String(describing: currentItem.imageUrl))")
            
        }
    }
}
