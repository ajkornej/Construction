//
//  ObjectTaskView.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 11.02.2025.
//

import SwiftUI
import AVKit
import Kingfisher

struct ObjectTaskView: View {
    
    @ObservedObject var viewModel = ObjectTaskViewModel()
    @Binding var navigationPath: NavigationPath
    @Binding var tappedTaskId: String

    var body: some View {
        ZStack{
            VStack(alignment: .leading){
  
                HStack{
                    Image("ticketText")
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text(viewModel.tisckets?.title)
                        .font(Fonts.Font_Callout)
                    Spacer()
                }
                .padding(.top, 4)
                
//                if viewModel.tisckets?.executors != nil {
//                    HStack{
//                        if viewModel.isProblem {
//                            Image("ticketError")
//                                .resizable()
//                                .frame(width: 20, height: 20)
//                        } else {
//                            Image("ticketNoError")
//                                .resizable()
//                                .frame(width: 20, height: 20)
//                        }
//                        
//                        Text(viewModel.tisckets?.progress)
//                            .font(Fonts.Font_Callout)
//                        
//                        Spacer()
//                    }
//                    .padding(.top, 4)
//                }
                
                HStack{
                    Image("calendar_month")
                        .resizable()
                        .frame(width: 20, height: 20)
                    
                    if viewModel.tisckets?.deadline != nil {
                        Text("до \(createDateTime(timestamp: viewModel.tisckets!.deadline))")
                            .font(Fonts.Font_Callout)
                        
                    }
                    Spacer()
                }
                .padding(.top, 4)
                
                if let objectIds = viewModel.tisckets?.objectIds, !objectIds.isEmpty {
                    HStack {
                        Image("ticketObjectIcon")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(objectIds.joined(separator: ", "))
                            .font(Fonts.Font_Callout)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                
                if viewModel.tisckets?.medias != [] {
                    MediaScrollView(medias: viewModel.tisckets?.medias ?? [])
                        .frame(height: 80)
                }
                
                HStack(alignment: .top) {
                    if viewModel.tisckets?.description != nil {
                        Image("ticketDescription")
                    }
                    
                    ScrollView{
                        Text(viewModel.tisckets?.description)
                    }
                }
                Spacer()
            }
            
            VStack{
                
                Spacer()
                
                if viewModel.tisckets?.buttonText != nil{
                    Button(action: {
                        viewModel.taskAction(taskId: tappedTaskId)
                    }) {
                        Text(viewModel.tisckets?.buttonText)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Colors.orange)
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .onAppear{
            DispatchQueue.main.async {
                viewModel.getTasks(for: tappedTaskId)
            }
            print("viewModel.isProblem \(viewModel.isProblem)")
            print("tappedTaskId \(tappedTaskId)")
        }
        .toolbar {
            ToolbarItem {
                Button {
                    
                } label: {
                    Image("chat_FILL0")
                }
            }
        }
    }
    func createDateTime(timestamp: Int) -> String {
        // Преобразуем метку времени (в миллисекундах) в секунды
        let unixTimeSeconds = Double(timestamp) / 1000.0
        let date = Date(timeIntervalSince1970: unixTimeSeconds)
        
        let dateFormatter = DateFormatter()
        // Используем текущую временную зону
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "d MMM yyyy'г.'"
        
        return dateFormatter.string(from: date)
    }
}

#Preview {
    @State var previewNavigationPath = NavigationPath()
    @State var tappedTaskId: String = "bc1c32e0-ae47-48dd-af80-de207c386dfb"
    
    return ObjectTaskView(viewModel: ObjectTaskViewModel(), navigationPath: $previewNavigationPath, tappedTaskId: $tappedTaskId)
}

struct MediaScrollView: View {
    let medias: [Media]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(medias) { media in
                    if let url = URL(string: media.originalUrl) {
                        KFImage(url)
                            .requestModifier { request in
                                if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                                    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                                }
                            }
                            .loadDiskFileSynchronously(false)
                            .cacheOriginalImage()
                            .placeholder {
                                Rectangle()
                                    .skeleton(
                                        with: true,
                                        animation: .pulse(),
                                        appearance: .solid(color: .gray.opacity(0.3)),
                                        shape: .rectangle
                                    )
                                    .frame(width: 76, height: 76)
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 76, height: 76)
                            .cornerRadius(12)
                            .clipped()
                    }
                }
            }
        }
    }
}
