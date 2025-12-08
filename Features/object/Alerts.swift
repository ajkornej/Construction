//
//  Alerts.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 11.10.2024.
//

import SwiftUI

struct Alerts: View {
    
    @Binding var navigationPath: NavigationPath
    @Binding var alertData: [AlertResponse]
    
    @Binding var tappedObjectId: String
    @Binding var medias: [Media]
    @Binding var selectedObject: ObjectResponse
    
    @Binding var selectedPriority: String
    @Binding var selectedType: String
    @Binding var selectedObjectId: String
    
    @Binding  var selectedPriorities: [String]
    @Binding  var selectedTypes: [String]
    @Binding  var selectedObjectIds: [String] 
    @State var isAlertLoading: Bool = false
    
    @Binding var tappedTaskId: String
    
    @State var isError: Bool = false
    // брать вместо objectId время в качесве идентификатора
    
    var body: some View {
        VStack{
            if isAlertLoading{
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                
                Spacer()
               
            } else if alertData.isEmpty {
                
                VStack {
                    
                    Image("visual-empty")
                        .resizable()
                        .frame(width: 140, height: 140)
                    
                    Text("Тут пока пусто")
                        .font(Fonts.Font_Headline1)
                    
                    //                    Text("Мастера будут оставлять фото и видео")
                    //                        .font(Fonts.Font_Body)
                }
                
            } else if isError {
                
                Spacer()
                
                Text("Ошибка. Что-то пошло не так...")
                
                Spacer()
                
            } else {
                List(alertData, id: \.self) { alert in
                    
                    Button(action: {
                        if !alert.deeplink.isEmpty {
                            print(alert.deeplink)
                            
                            handleDeepLinkDirect(alert.deeplink)
                        } else {
                            if tappedObjectId != alert.objectId {
                                medias = []
                                tappedObjectId = alert.objectId ?? ""
                            }
                            getObject { success in
                                if success {
                                    print("Request successful")
                                } else {
                                    print("Request failed")
                                }
                            }
//                            navigationPath.append(Destination.objectDetails)
                        }
                    }, label: {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(alert.title)
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                            Text(alert.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.top, 4)
                            Text(formatDate(timestamp: alert.date))
                                .font(Fonts.Font_Footnote)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .padding(.bottom, 16)
                            
                            RoundedRectangle(cornerRadius: 0)
                                .frame(height: 8)
                                .foregroundColor(alert.priorityColor)
                                .frame(maxWidth: .infinity) // Полоска приоритета на всю ширину
                                .clipShape(RoundedCorners(radius: 10, corners: [.bottomLeft, .bottomRight])) // Применяем кастомные углы
                                .padding(.bottom, 0)
                            
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
                            
                        )
                    })
                    .listStyle(PlainListStyle())
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        getAlerts()
                    }
                }
            }
        }
        .navigationTitle("Оповещения")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear{
            getAlerts()
        
            print("\(selectedPriority)")
            print(alertData)
        }
        .toolbar{
            Button(action: {
                navigationPath.append(Destination.alertsfilters)
            }, label: {
               Image("tune_24")
            })
        }
    }
    func handleDeepLinkDirect(_ deepLink: String) {
        guard let url = URL(string: deepLink),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }

        let pathComponents = components.path.split(separator: "/").map(String.init)

        guard pathComponents.count >= 3 else {
            print("Not enough path components")
            return
        }

        let type = pathComponents[0] // "objects" или "tasks"
        let id = pathComponents.last! // ID объекта или задачи
        var userInfo: [String: Any] = ["type": type, "id": id]

        // Извлекаем параметры запроса (например, openChat)
        if let queryItems = components.queryItems {
            for item in queryItems {
                userInfo[item.name] = item.value
            }
        }

        // Вызываем обработчик напрямую
        DispatchQueue.main.async {
            print("📢 Вызываем обработчик напрямую с userInfo: \(userInfo)")
            self.processDeepLink(userInfo: userInfo)
        }
    }

    // Функция обработки deep link без NotificationCenter
    func processDeepLink(userInfo: [String: Any]) {
        guard let type = userInfo["type"] as? String,
              let id = userInfo["id"] as? String else { return }

        if type == "objects" {
            DispatchQueue.main.async {
                self.tappedObjectId = id
                self.navigationPath.append(Destination.objectDetails)

                // Проверяем параметр openChat
                if let openChat = userInfo["openChat"] as? String, openChat == "true" {
                    self.navigationPath.append(Destination.chat)
                }
            }
        } else if type == "tasks" {
            DispatchQueue.main.async {
                self.tappedTaskId = id
                self.navigationPath.append(Destination.taskvew)
            }
        }
    }
    
    func getAlerts() {

        isAlertLoading = true
        
        let requestBody = AlertsRequest(
            page: 0,
            limit: 30,
            filters: Filters(
                priorities: selectedPriorities,
                objectIds: selectedObjectIds,
                types: selectedTypes
            )
        )
        NetworkAccessor.shared.post("/alerts", body: requestBody) { (result: Result<AlertsContentResponse, Error>, statusCode: Int?) in
            switch result {
            case .success(let response):
                print("Decoded Response: \(response)")
                DispatchQueue.main.async {
                    self.alertData = response.content  // Обновляем alertData в главном потоке
                    isAlertLoading = false
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                isAlertLoading = false
            }
        }
    }
    
    func getObject(completion: @escaping (Bool) -> Void) {
        NetworkAccessor.shared.get("/objects/\(tappedObjectId)") { (result: Result<ObjectResponse, Error>, statusCode: Int?) in
            switch result {
            case .success(let data):
                selectedObject = data
                print("Success: \(data)")
            case .failure(let error):
                print("Error: \(error)")
                isError = true
            }
        }
    }
    
    // Функция для форматирования даты
    func formatDate(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM yyyy" 
        return formatter.string(from: date)
    }
}

struct AlertsContentResponse: Codable {
    let page: Int
    let limit: Int
    let content: [AlertResponse]  // Здесь декодируется массив AlertResponse
    let totalPages: Int
}

extension AlertResponse {
    var priorityColor: Color {
        switch self.priority {
        case .red:
            return Colors.Red
        case .yellow:
            return Colors.Yellow
        case .info:
            return Colors.Blue
        }
    }
    
    // Вычисляем, сколько дней прошло с даты события
    var timePassed: String {
        let daysPassed = calculateDaysPassed(since: date)
        return daysPassed == 0 ? "Сегодня" : "\(daysPassed) дней"
    }
    
    func formattedDate(from timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU") // Устанавливаем локаль на русскую
        dateFormatter.dateFormat = "dd MMM HH:mm"
        return dateFormatter.string(from: date)
    }

    // Функция для расчета количества дней, прошедших с указанной даты
    private func calculateDaysPassed(since timestamp: Int64) -> Int {
        let eventDate = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let currentDate = Date()
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: eventDate, to: currentDate)
        
        return components.day ?? 0  // Если расчет не удался, возвращаем 0
    }
}

struct AlertsRequest: Codable {
    let page: Int
    let limit: Int
    let filters: Filters
}

struct Filters: Codable {
    let priorities: [String]
    let objectIds: [String]
    let types: [String]
}

struct AlertResponse: Codable, Hashable {
    let title: String
    let subtitle: String
    let priority: Priority
    let date: Int64
    let deeplink: String
    let objectId: String?
    let type: AlertType
}

enum Priority: String, Codable {
    case red = "RED"
    case yellow = "YELLOW"
    case info = "INFO"
}

enum AlertType: String, Codable, Hashable {
    case reportIsOverdue = "REPORT_IS_OVERDUE"
    case objectDeadlineSoon = "OBJECT_DEADLINE_SOON"
    case noResponseInChat = "NO_RESPONSE_IN_CHAT"
    case documentToBeApproved = "DOCUMENT_TO_BE_APPROVED"
    case noOriginalDocument = "NO_ORIGINAL_DOCUMENT"
    case tasks = "TASKS"  // Добавляем
    case ticketsVerification = "TICKETS_VERIFICATION"  // Добавляем
}

// Кастомная форма для закругления только определенных углов
struct RoundedCorners: Shape {
    var radius: CGFloat = 10
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


