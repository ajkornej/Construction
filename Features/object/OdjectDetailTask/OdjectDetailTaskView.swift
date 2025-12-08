//
//  ObjectDetailTaskView.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 13.05.2025.
//

import SwiftUI

struct ObjectDetailTaskView: View {
    
    @Binding var tappedObjectId: String

    @ObservedObject var viewModel = ObjectDetailTaskViewModel()
    
    @Binding var navigationPath: NavigationPath
    
    @Binding var tappedTaskId: String
    
    var body: some View {
        VStack{
            
            if viewModel.tasksObjectDetails.isEmpty{
                
                Spacer()
                
                Image("visual-empty")
                    .resizable()
                    .frame(width: 140, height: 140)
                
                Text("Здесь будут задачи")
                    .font(Fonts.Font_Headline1)
                
                Spacer()
                
            } else {
                //                Text(viewModel.tasksObjectDetails.description)
                
                
                ScrollView {
                    LazyVStack() {
                        ForEach(viewModel.tasksObjectDetails) { task in
                            TaskCardView(navigationPath: $navigationPath, tappedTaskId: $tappedTaskId, task: task)
                                .padding(.horizontal,16)
                                .padding(.top, 8)
                        }
                    }
                    
                }
                .padding(.top, 16)
            }
        }
        .onAppear{
            viewModel.loadTask(for: tappedObjectId)
            print()
        }
    }
}

struct TaskCardView: View {
    @Binding var navigationPath: NavigationPath
    @Binding var tappedTaskId: String
    let task: TaskModel
    
    // Форматирование даты из timestamp
    private var formattedDeadline: String {
        let date = Date(timeIntervalSince1970: TimeInterval(task.deadline))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyyг."
        return "до \(formatter.string(from: date))"
    }
    
    // Форматирование имени создателя
    private var creatorName: String {
        "\(task.creator.name) \(task.creator.surname)"
    }
    
    // Форматирование должности создателя
    private var creatorJobTitle: String {
        task.creator.jobTitle
    }
    
    var body: some View {
        HStack{
            VStack(alignment: .leading/*, spacing: 12*/) {
                // Заголовок карточки
                
                Text(task.title)
                    .font(Fonts.Font_Headline2)
                    .foregroundColor(Color.black)
                
                
                
                Text(formattedDeadline)
                    .font(Fonts.Font_Callout)
                    .foregroundColor(Colors.textFieldOverlayGray)
                    .padding(.top, -4)
                
                // Информация о создателе
                HStack {
                    Text(creatorName)
                        .font(Fonts.Font_Callout)
                        .foregroundColor(Colors.orange)
                    
                    Text(creatorJobTitle)
                        .font(Fonts.Font_Callout)
                        .foregroundColor(Colors.orange)
                }
                .padding(.top, -2)
            }
            
            Spacer()
            
            VStack{
                Spacer()
                
                Button(action: {
                    tappedTaskId = task.taskId.uuidString
                    navigationPath.append(Destination.taskvew)
                    print("tappedTaskId \(tappedTaskId)")
                    
                }) {
                    Text(task.buttonText ?? "Перейти")
                        .font(Fonts.Font_Footnote)
                        .foregroundColor(.white)
                        .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        .background(Colors.orange)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Colors.orange, lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(task.isProblem ? Color.red : Colors.textFieldOverlayGray, lineWidth: 1)
        )
        .frame(height: 92)
    }
}

// Расширение для идентификации
extension TaskModel: Identifiable {
    var id: UUID { taskId }
}



//#Preview {
//    
//    @State var previewNavigationPath = NavigationPath()
//    @State var tappedTaskId: String = "bc1c32e0-ae47-48dd-af80-de207c386dfb"
//    
//    OdjectDetaolTaskView(navigationPath: $previewNavigationPath, tappedTaskId: $tappedTaskId)
//}
