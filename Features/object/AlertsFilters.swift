
import SwiftUI

struct AlertsFilters: View {
    
    @Binding var alertData: [AlertResponse]
    @Binding var navigationPath: NavigationPath
    
    @Binding var selectedPriority: String
    @Binding var selectedType: String
    @Binding var selectedObjectId: String
    
    @Binding var selectedPriorities: [String]
    @State private var tempSelectedPriorities: [String] = []
    
    @Binding var selectedTypes: [String]
    @State private var tempselectedTypes: [String] = []
    
    @Binding var selectedObjectIds: [String]
    @State private var tempselectedObjectIds: [String] = []
    
    @State private var prioritySheetShown = false
    @State private var typeSheetShown = false
    @State private var objectSheetShown = false
    
    @Binding var dataResponseObjectAll: [ObjectResponse]
    
    @State private var searchText: String = ""
    @State var isSearchActive = false
    @FocusState var isSearchFieldFocused2: Bool
    
    let priorities = [
        ("RED", "Срочные"),
        ("YELLOW", "Важные"),
        ("INFO", "Информационные")
    ]
    let types = [
        ("REPORT_IS_OVERDUE", "Отчёт просрочен"),
        ("OBJECT_DEADLINE_SOON", "Скоро сдача объекта"),
        ("TASKS", "Задачи"),
        ("NO_RESPONSE_IN_CHAT", "Нет ответа в чате")
    ]
    
    var filteredAndSortedObjects: [ObjectResponse] {
        let lowercasedQuery = searchText.lowercased()
        return dataResponseObjectAll
            .filter { object in
                let isAddressMatch = object.address.lowercased().contains(lowercasedQuery)
                let isStatusMatch = object.status.lowercased().contains(lowercasedQuery)
                let isObjectIdMatch = String(object.objectId).contains(lowercasedQuery)
                return isAddressMatch || isStatusMatch || (!isAddressMatch && isObjectIdMatch)
            }
            .sorted { obj1, obj2 in
                let firstAddressIndex = obj1.address.lowercased().range(of: lowercasedQuery)?.lowerBound.utf16Offset(in: obj1.address) ?? Int.max
                let firstStatusIndex = obj1.status.lowercased().range(of: lowercasedQuery)?.lowerBound.utf16Offset(in: obj1.status) ?? Int.max
                let firstObjectIdIndex = String(obj1.objectId).range(of: lowercasedQuery)?.lowerBound.utf16Offset(in: String(obj1.objectId)) ?? Int.max

                let secondAddressIndex = obj2.address.lowercased().range(of: lowercasedQuery)?.lowerBound.utf16Offset(in: obj2.address) ?? Int.max
                let secondStatusIndex = obj2.status.lowercased().range(of: lowercasedQuery)?.lowerBound.utf16Offset(in: obj2.status) ?? Int.max
                let secondObjectIdIndex = String(obj2.objectId).range(of: lowercasedQuery)?.lowerBound.utf16Offset(in: String(obj2.objectId)) ?? Int.max
                
                if firstAddressIndex != secondAddressIndex {
                    return firstAddressIndex < secondAddressIndex
                } else if firstStatusIndex != secondStatusIndex {
                    return firstStatusIndex < secondStatusIndex
                } else {
                    return firstObjectIdIndex < secondObjectIdIndex
                }
            }
    }
    
    var body: some View {
        VStack {
            Text("Важность")
                .font(Fonts.Font_Callout)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, 12)
            
            Button(action: {
                prioritySheetShown = true
                tempSelectedPriorities = selectedPriorities
            }) {
                HStack {
                    Text(tempSelectedPriorities.isEmpty ? "Выберите важность" : selectedPrioritiesText())
                        .foregroundColor(tempSelectedPriorities.isEmpty ? Color.gray : .black)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    if !tempSelectedPriorities.isEmpty {
                        Button(action: {
                            tempSelectedPriorities = [] // Очищаем временный выбор
                        }, label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        })
                    } else {
                        Image(systemName: prioritySheetShown ? "chevron.up" : "chevron.down")
                            .foregroundColor(Color.gray)
                    }
                }
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray, lineWidth: 1))
                .cornerRadius(18)
            }
            .sheet(isPresented: $prioritySheetShown, onDismiss: {
                // Ничего не сбрасываем
            }) {
                VStack {
                    HStack {
                        Text("Важность")
                            .font(Font.custom("Roboto", size: 20).weight(.semibold))
                            .padding(.top, 24)
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                    
                    ForEach(priorities, id: \.0) { priority, text in
                        VStack {
                            HStack {
                                Text(text)
                                    .foregroundColor(colorForPriority(priority))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                if tempSelectedPriorities.contains(priority) {
                                    Image(systemName: "checkmark.square.fill")
                                        .foregroundColor(Colors.orange)
                                } else {
                                    Image(systemName: "square")
                                        .foregroundColor(Colors.orange)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if tempSelectedPriorities.contains(priority) {
                                    tempSelectedPriorities.removeAll(where: { $0 == priority })
                                } else {
                                    tempSelectedPriorities.append(priority)
                                }
                            }
                            if priority != priorities.last?.0 {
                                Divider()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        prioritySheetShown = false
                    }) {
                        Text("Применить")
                            .foregroundColor(Color.white)
                            .font(Fonts.Font_Headline2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Colors.orange)
                            .cornerRadius(16)
                            .padding(.bottom, 8)
                    }
                }
                .presentationDetents([.medium, .height(320)])
                .padding(.horizontal, 16)
            }
            
            Text("Тип")
                .font(Fonts.Font_Callout)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, 12)
            
            Button(action: {
                typeSheetShown = true
                tempselectedTypes = selectedTypes
            }) {
                HStack {
                    Text(tempselectedTypes.isEmpty ? "Выберите тип" : selectedTypesText())
                        .foregroundColor(tempselectedTypes.isEmpty ? Color.gray : .black)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    if !tempselectedTypes.isEmpty {
                        Button(action: {
                            tempselectedTypes = [] // Очищаем временный выбор
                        }, label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        })
                    } else {
                        Image(systemName: typeSheetShown ? "chevron.up" : "chevron.down")
                            .foregroundColor(Color.gray)
                    }
                }
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray, lineWidth: 1))
                .cornerRadius(18)
            }
            .sheet(isPresented: $typeSheetShown, onDismiss: {
                // Ничего не сбрасываем
            }) {
                VStack {
                    HStack {
                        Text("Тип")
                            .font(Font.custom("Roboto", size: 20).weight(.semibold))
                            .padding(.top, 24)
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                    
                    ForEach(types, id: \.0) { type, text in
                        VStack {
                            HStack {
                                Text(text)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                if tempselectedTypes.contains(type) {
                                    Image(systemName: "checkmark.square.fill")
                                        .foregroundColor(Colors.orange)
                                } else {
                                    Image(systemName: "square")
                                        .foregroundColor(Colors.orange)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if tempselectedTypes.contains(type) {
                                    tempselectedTypes.removeAll(where: { $0 == type })
                                } else {
                                    tempselectedTypes.append(type)
                                }
                            }
                            if type != types.last?.0 {
                                Divider()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        typeSheetShown = false
                    }) {
                        Text("Применить")
                            .foregroundColor(Color.white)
                            .font(Fonts.Font_Headline2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Colors.orange)
                            .cornerRadius(16)
                            .padding(.bottom, 8)
                    }
                }
                .presentationDetents([.medium, .height(520)])
                .padding(.horizontal, 16)
            }
            
            Text("Объекты")
                .font(Fonts.Font_Callout)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, 12)
            
            Button(action: {
                objectSheetShown = true
                tempselectedObjectIds = selectedObjectIds
            }) {
                HStack {
                    Text(tempselectedObjectIds.isEmpty ? "Выберите объекты" : selectedObjectsText())
                        .foregroundColor(tempselectedObjectIds.isEmpty ? Color.gray : .black)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    if !tempselectedObjectIds.isEmpty {
                        Button(action: {
                            tempselectedObjectIds = [] // Очищаем временный выбор
                        }, label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        })
                    } else {
                        Image(systemName: objectSheetShown ? "chevron.up" : "chevron.down")
                            .foregroundColor(Color.gray)
                    }
                }
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray, lineWidth: 1))
                .cornerRadius(18)
            }
            .sheet(isPresented: $objectSheetShown, onDismiss: {
            }) {
                VStack {
                    HStack {
                        if isSearchActive {
                            
                            FocusedTextFieldView(text: $searchText)
                                .padding(.top, 18)
                            
                            
//                            TextField("Поиск", text: $searchText)
//                                .focused($isSearchFieldFocused2)
//                                .accentColor(Colors.orange)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .padding(.top, 24)
//                                .padding(.leading, 16)
//                                .onChange(of: isSearchFieldFocused2) { newValue in
//                                    print("isSearchFieldFocused \(newValue)")
//                                }
                            
                            
                            Button(action: {
                                withAnimation {
                                    isSearchActive.toggle()
                                    isSearchFieldFocused2 = false
                                }
                                searchText = ""
                            }, label: {
                                Image("close")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .padding(.top, 18)
                            })
                        } else {
                            Text("Объекты")
                                .font(Font.custom("Roboto", size: 20).weight(.semibold))
                                .padding(.top, 24)
                                .padding(.horizontal)
                            
                            Spacer()
                            
                            Button(action: {
                                isSearchActive.toggle()
                                isSearchFieldFocused2 = true
                                print("isSearchFieldFocused \(isSearchFieldFocused2)")
                                
                            }, label: {
                                Image("searchBlack")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.black)
                                    .padding(.top, 24)
                            })
                        }
                    }
                    if searchText == "" {
                        ScrollView {
                            ForEach(dataResponseObjectAll, id: \.objectId) { object in
                                VStack {
                                    HStack {
                                        VStack {
                                            Text("ИД \(object.objectId)")
                                                .font(Fonts.Font_Headline2)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Text("\(object.address)")
                                                .font(Fonts.Font_Callout)
                                                .foregroundColor(Colors.boldGray)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding()
                                        if tempselectedObjectIds.contains(object.objectId) {
                                            Image(systemName: "checkmark.square.fill")
                                                .foregroundColor(Colors.orange)
                                        } else {
                                            Image(systemName: "square")
                                                .foregroundColor(Colors.orange)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if tempselectedObjectIds.contains(object.objectId) {
                                            tempselectedObjectIds.removeAll(where: { $0 == object.objectId })
                                        } else {
                                            tempselectedObjectIds.append(object.objectId)
                                        }
                                    }
                                    if object.objectId != dataResponseObjectAll.last?.objectId {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    } else {
                        if filteredAndSortedObjects == [] {
                            VStack {
                                
                                Spacer()
                                
                                Image("visual-display-that-the-file-has-not-been-found")
                                    .resizable()
                                    .frame(width: 140, height: 140)
                                Text("Ничего не найдено")
                                    .font(Fonts.Font_Headline2)
                                    .padding(.top, 4)
                                Text("Попробуйте уточнить поисковый")
                                    .font(Fonts.Font_Callout)
                                Text("запрос")
                                    .font(Fonts.Font_Callout)
                                Spacer()
                            }
                        }
                        ScrollView {
                            ForEach(filteredAndSortedObjects, id: \.objectId) { object in
                                VStack {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("ИД \(object.objectId)")
                                                .font(Fonts.Font_Headline2)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Text("\(object.address)")
                                                .font(Fonts.Font_Callout)
                                                .foregroundColor(Colors.boldGray)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding()
                                        if tempselectedObjectIds.contains(object.objectId) {
                                            Image(systemName: "checkmark.square.fill")
                                                .foregroundColor(Colors.orange)
                                        } else {
                                            Image(systemName: "square")
                                                .foregroundColor(Colors.orange)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if tempselectedObjectIds.contains(object.objectId) {
                                            tempselectedObjectIds.removeAll(where: { $0 == object.objectId })
                                        } else {
                                            tempselectedObjectIds.append(object.objectId)
                                        }
                                    }
                                    if object.objectId != filteredAndSortedObjects.last?.objectId {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                    
                    Button(action: {
                        objectSheetShown = false
                    }) {
                        Text("Применить")
                            .foregroundColor(Color.white)
                            .font(Fonts.Font_Headline2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Colors.orange)
                            .cornerRadius(16)
                            .padding(.bottom, 16)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
            
            Button(action: {
                selectedPriorities = tempSelectedPriorities
                selectedTypes = tempselectedTypes
                selectedObjectIds = tempselectedObjectIds
                navigationPath.removeLast(1)
            }, label: {
                Text("Применить")
                    .foregroundColor(Color.white)
                    .font(Fonts.Font_Headline2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Colors.orange)
                    .cornerRadius(16)
                    .padding(.bottom, 8)
            })
        }
        .navigationTitle("Фильтрация")
        .padding(.horizontal, 16)
        .onAppear {
            tempSelectedPriorities = selectedPriorities
            tempselectedTypes = selectedTypes
            tempselectedObjectIds = selectedObjectIds
        }
    }
    
    func selectedPrioritiesText() -> String {
        return priorities
            .filter { tempSelectedPriorities.contains($0.0) } // Используем tempSelectedPriorities
            .map { $0.1 }
            .joined(separator: ", ")
    }
    
    func selectedTypesText() -> String {
        return types
            .filter { tempselectedTypes.contains($0.0) } // Используем tempselectedTypes
            .map { $0.1 }
            .joined(separator: ", ")
    }
    
    func colorForPriority(_ priority: String) -> Color {
        switch priority {
        case "RED":
            return .red
        case "YELLOW":
            return .yellow
        case "INFO":
            return .blue
        default:
            return .black
        }
    }
    
    func selectedObjectsText() -> String {
        if tempselectedObjectIds.isEmpty { // Используем tempselectedObjectIds
            return "Выберите объекты"
        } else {
            let selectedObjectTexts = tempselectedObjectIds.map { "Объект №\($0)" }
            return selectedObjectTexts.joined(separator: ", ")
        }
    }
}

struct FocusedTextFieldView: View {
    @Binding var text: String
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
       
        TextField("Введите что-то", text: $text)
            .focused($isTextFieldFocused)
            .accentColor(Colors.orange)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, 8)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
    }
}

// Функция для применения фильтров и выполнения запроса
//    func applyFilters() {
//        // Обновляем значения фильтров на основе выбора пользователя
//        selectedPriorities = selectedPriority != nil ? [selectedPriority] : []
//        selectedObjectIds = selectedObjectId != nil ? [selectedObjectId] : []
//        selectedTypes = selectedType != nil ? [selectedType] : []
//
//        // Выполняем запрос с фильтрами
//        let requestBody = AlertsRequest(
//            page: 0,
//            limit: 10,
//            filters: Filters(
//                priorities: selectedPriorities,
//                objectIds: selectedObjectIds,
//                types: selectedTypes
//            )
//        )
//
//        NetworkAccessor.shared.post("/alerts", body: requestBody) { (result: Result<AlertsContentResponse, Error>, statusCode: Int?) in
//            switch result {
//            case .success(let response):
//                print("Decoded Response: \(response)")
//                DispatchQueue.main.async {
//                    alertData = response.content  // Обновляем alertData в главном потоке
//                }
//            case .failure(let error):
//                print("Error: \(error.localizedDescription)")
//            }
//        }
//    }
//struct AlertsFilters_Previews: PreviewProvider {
//    
//    @State static var tappedObjectId: Int = 1 // Пример данных
//    @State static var navigationPath = NavigationPath() // Пример пути навигации
//    
//    @State static var alertData: [AlertResponse] = [
//           AlertResponse(
//               title: "Просрочен отчёт",
//               subtitle: "Объект №4",
//               priority: .red,
//               date: 1633052800000,
//               deeplink: "https://example.com",
//               objectId: 123,
//               type: .reportIsOverdue
//           ),
//           AlertResponse(
//               title: "Просрочен отчёт",
//               subtitle: "Объект №532235",
//               priority: .yellow,
//               date: 1633052900000,
//               deeplink: "https://example.com",
//               objectId: 456,
//               type: .documentToBeApproved
//           )
//       ]
//    
//    static var previews: some View {
//        AlertsFilters(navigationPath: $navigationPath, alertData: $alertData)
//    }
//}

