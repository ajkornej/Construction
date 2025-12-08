//
//  ObjectChecks.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 26.01.2025.
//

import SwiftUI

struct ObjectChecksView: View {
    
    @Binding var navigationPath: NavigationPath
    
    @Binding var selectedFile: String

    @StateObject
    var viewModel: ObjectChecksViewModel
    
    @Binding var selectedObject: ObjectResponse
    
    @State var sheetShow: Bool = false
    
    @State var filterTitle: String = "Все"
    
    var body: some View {
        ZStack{
            
            
            
            if viewModel.tickets.isEmpty && viewModel.isLoading == false {
                VStack {
                    Image("visual-empty")
                        .resizable()
                        .frame(width: 140, height: 140)
                    
                    Text("Здесь будут чеки по объекту")
                        .font(Fonts.Font_Headline1)
                    
                    Text("Доп. расходы на материалы,")
                        .font(Fonts.Font_Callout)
                    
                    Text("уборку и т.д.")
                        .font(Fonts.Font_Callout)
                }
            }
            
            VStack{
                Button(action: {
                    sheetShow.toggle()
                }, label: {
                    HStack{
                        Spacer()
                        Text(filterTitle)
                            .font(Fonts.Font_Footnote)
                            .foregroundColor(Colors.textFieldOverlayGray)
                        
                        Image("sort")
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                })
                .sheet(isPresented: $sheetShow) {
                    VStack{
                        List {
                            
                            Button(action: {
                                viewModel.selectedNomenclaturesStruct = nil
                                Task.detached { await viewModel.trigger(.onAppear) }
                                sheetShow = false
                            }, label: {
                                Text("Все")
                                    .foregroundColor(.black)
//                                    .foregroundColor(Colors.textFieldOverlayGray)
                            })
                            .padding(.top, 16)
                            
                            
                            ForEach(viewModel.nomenclaturesStruct, id: \.nomenclatureId) { nomen in
                                
                                Button(action: {
                                    viewModel.selectedNomenclaturesStruct = nomen.nomenclatureId
                                    Task.detached { await viewModel.trigger(.onAppear) }
                                    print("tapped \(String(describing: viewModel.selectedNomenclaturesStruct)) \(nomen.nomenclatureId)")
                                    filterTitle = nomen.title
                                    sheetShow = false
                                }, label: {
                                    Text(nomen.title)
                                        .foregroundColor(.black)
//                                        .foregroundColor(Colors.textFieldOverlayGray)
                                })
                            }
                            .listRowSeparator(.hidden)
                        }
                        
                    }
                    .scrollIndicators(.hidden)
                    .listStyle(PlainListStyle())
                    .presentationDetents([.medium, .large])
                }
                
                Spacer()
            }
        
            ZStack {
                ScrollView {
                    ForEach(viewModel.tickets, id: \.ticketId) { check in
                        Button(action: {
                            
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(check.title)
                                            .font(Fonts.Font_Headline2)
                                            .foregroundColor(Color.black)
                                        Spacer()
                                    }
                                    
                                    HStack {
                                        Text(check.nomenclature)
                                            .font(Fonts.Font_Callout)
                                            .foregroundColor(Colors.boldGray)
                                        
                                        Text("·")
                                            .font(Fonts.Font_Callout)
                                            .foregroundColor(Colors.boldGray)
                                        
                                        Text(viewModel.createDateTime(timestamp: String(check.date)))
                                            .font(Fonts.Font_Callout)
                                            .foregroundColor(Colors.boldGray)
                                        
                                        Spacer()
                                    }
                                    .padding(.top, -4)
                                    
                                    HStack {
                                        Text("\(check.creator.name) \(formatInitials(check.creator))")
                                            .font(Fonts.Font_Callout)
                                            .foregroundColor(Colors.orange)
                                        Spacer()
                                    }
                                    .padding(.top, -4)
                                }
                                
                                VStack {
                                    Text(check.financialImpact)
                                        .font(Fonts.Font_Callout)
                                        .foregroundColor(Colors.boldGray)
                                    
                                    if check.downloadUrl != nil {
                                        Button(action: {
                                            selectedFile = check.downloadUrl ?? ""
                                            navigationPath.append(Destination.pdfview)
                                        }, label: {
                                            HStack {
                                                Text("Открыть")
                                                    .foregroundColor(Color.white)
                                                    .font(Fonts.Font_Footnote)
                                            }
                                            .frame(width: 74)
                                            .frame(height: 24)
                                            .background(Colors.orange)
                                            .cornerRadius(8)
                                        })
                                    } else {
                                        Text("Открыть")
                                            .foregroundColor(.clear)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 92)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Colors.lightGrayOverlay, lineWidth: 1)
                        )
                    }
                    Spacer()
                        .frame(height: 80)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .refreshable {
                    await viewModel.refreshChecks()
                }
                    
                if viewModel.authResponse?.permissions.contains("WRITE_TICKETS") == true && selectedObject.status == "IN_PROGRESS" {
                    VStack {
                        Spacer()
                        Button(action: {
                            viewModel.showAddCheckBottomSheet = true
                        }, label: {
                            HStack {
                                Text("Добавить чек")
                                    .foregroundColor(Color.white)
                                    .font(Fonts.Font_Headline2)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Colors.orange)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                        })
                        .ignoresSafeArea()
                    }
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .onAppear {
            Task.detached { await viewModel.trigger(.onAppear) }
            
            viewModel.getOnomenclatures(completion: { success in
                if success {
                    print("getObjectCurrent success")
                } else {
                    print("getObjectCurrent failed")
                }
            })
        }
        .sheet(isPresented: $viewModel.showAddCheckBottomSheet) {
            VStack {
                HStack{
                    Text("Способ загрузки")
                        .font(Font.custom("Roboto", size: 20).weight(.semibold))
                        .padding(.top, 24)
                    
                    Spacer()
                }
                
                Button(action: {
                    viewModel.showAddCheckBottomSheet = false
                    navigationPath.append(Destination.createcheckcamera)
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
                    navigationPath.append(Destination.createcheck)
                    viewModel.showAddCheckBottomSheet = false
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
    private func formatInitials(_ creator: GetTicketsResponse.Creator) -> String {
        let nameInitial = creator.name.prefix(1).uppercased()
        let surnameInitial = creator.surname.prefix(1).uppercased()
        
        // Безопасное извлечение инициала отчества
        let patronymicInitial = creator.patronymic?.prefix(1).uppercased() ?? ""
        
        return "\(surnameInitial)\(nameInitial)\(patronymicInitial)"
    }
}

