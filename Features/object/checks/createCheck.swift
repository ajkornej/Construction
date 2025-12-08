//
//  createCheck.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 26.01.2025.
//

import SwiftUI

struct createCheck: View {
    
    @Binding var navigationPath: NavigationPath
    @Binding var tappedObjectId: String
    
    @StateObject
    var viewModel: createCheckViewModel
    @Binding var generatedPDFURL: URL?
    @Binding var capturedMediaDoc: [CapturedMediaDocument]
    
    var body: some View {
        VStack{
            ScrollView {
                
                Text("Тип")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)
                
                Button {
                    viewModel.checkTypeSheetShow = true
                } label: {
                    HStack {
                        Text((viewModel.checkTypeString.isEmpty) ? "Выберите тип" : viewModel.checkTypeString)
                            .foregroundColor((viewModel.checkTypeString == "") ? Colors.textFieldOverlayGray : Color.black)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            
                        Spacer()
                        
                        Image(systemName: viewModel.checkTypeSheetShow ? "chevron.up" : "chevron.down")
                            .foregroundColor(Colors.textFieldOverlayGray)
                    }
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(viewModel.selectedTypeCorrect ? Colors.textFieldOverlayGray : Color.red))
                    .cornerRadius(18)
                }
                .sheet(isPresented: $viewModel.checkTypeSheetShow) {
                    TypeCheckSheet(viewModel: viewModel)
                }
                .onChange(of: viewModel.checkTypeString) { newValue in
                    viewModel.selectedTypeCorrect = true
                }
                
                Text("Номенклатура")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)
                
                Button {
                        viewModel.sheetNomenklatureTypeShown = true
                } label: {
                    HStack{
                        Text(viewModel.nomenclatureString.isEmpty ? "Выберите Номенклатуру" : viewModel.nomenclatureString)
                            .foregroundColor((viewModel.nomenclatureString.isEmpty) ? Colors.textFieldOverlayGray : Color.black)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        
                        Spacer()
                        
                        Image(systemName: viewModel.sheetNomenklatureTypeShown ? "chevron.up" : "chevron.down")
                            .foregroundColor(Colors.textFieldOverlayGray)
                    }
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(viewModel.nomenclatureStringCorrect ? Colors.textFieldOverlayGray : Color.red))
                    .cornerRadius(18)
                }
                .sheet(isPresented: $viewModel.sheetNomenklatureTypeShown) {
                    NomenclaturesSheet(viewModel: viewModel)
                }
                .onChange(of: viewModel.nomenclatureString) { newValue in
                    viewModel.nomenclatureStringCorrect = true
                }
                
                Text("Название")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)
                
                TextField("",text: $viewModel.documentName, prompt: Text("Введите название").foregroundColor(Colors.textFieldOverlayGray))
                    .autocapitalization(.none)
                    .foregroundColor(.black)
                    .disableAutocorrection(true)
                    .textContentType(.emailAddress)
                    .accentColor(Colors.orange)
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(viewModel.documentNameCorrect ? Colors.textFieldOverlayGray : Color.red))
                    .cornerRadius(18)
                    .padding(.top, -2)
                    .onChange(of: viewModel.documentName) { newValue in
                        viewModel.documentNameCorrect = true
                    }
                
                Text("Cумма")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)
                
                TextField("", text: $viewModel.documentPrice, prompt: Text("Введите сумму").foregroundColor(Colors.textFieldOverlayGray))
                    .autocapitalization(.none)
                    .foregroundColor(.black)
                    .disableAutocorrection(true)
                    .keyboardType(.numberPad)
                    .accentColor(Colors.orange)
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(viewModel.documentPriceCorrect ? Colors.textFieldOverlayGray : Color.red))
                    .cornerRadius(18)
                    .padding(.top, -2)
                    .onChange(of: viewModel.documentPrice) { newValue in
                        viewModel.documentPriceCorrect = !newValue.isEmpty && Double(newValue) != nil
                    }
                
                Text("Файл")
                    .font(Fonts.Font_Callout)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.top, 12)
                
                ZStack {
                    
                    if let document = viewModel.selectedDocument {
                        Text("Выбранный документ: \(document.lastPathComponent)")
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                            .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(Colors.textFieldOverlayGray))
                            .cornerRadius(18)
                            .padding(.top, -2)
                            .onTapGesture {
                                viewModel.showingDocumentPicker = true
                            }
                    } else if let generatedPDF = generatedPDFURL {
                        Text("\(generatedPDF.lastPathComponent)")
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                            .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(Colors.textFieldOverlayGray))
                            .cornerRadius(18)
                            .padding(.top, -2)
                            .onTapGesture {
                                viewModel.showingDocumentPicker = true
                            }
                    } else {
                        Text("Выберите файл")
                            .foregroundColor(Colors.textFieldOverlayGray)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                            .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(Colors.textFieldOverlayGray))
                            .cornerRadius(18)
                            .padding(.top, -2)
                            .onTapGesture {
                                viewModel.showingDocumentPicker = true
                            }
    
                    }
                    HStack{
                        Spacer()
                        
                        Image("attach_file")
                            .padding(.horizontal, 16)
                    }
                    .onTapGesture {
                        viewModel.showingDocumentPicker = true
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            Button(action: {

                viewModel.fieldsIsCorrect()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Даем время на обновление состояния
                       print("fieldsIsCorrect \(viewModel.fieldIsCorrect)")
                    
                    if viewModel.fieldIsCorrect {
                        
                        viewModel.IsUploadInProcess = true
                        
                        let documentURL = viewModel.selectedDocument ?? generatedPDFURL
                        
                        let checkRequest = PostCheck(
                            nomenclatureId: viewModel.selectednomenclatureId,
                            title: viewModel.documentName,
                            financialImpact: Double(viewModel.documentPrice) ?? 0,
                            isOutcome: viewModel.isOutcome)
                        
                        viewModel.uploadDocument(fileURL: documentURL, checkRequest: checkRequest, objectId: tappedObjectId) { result in
                            
                            switch result {
                                
                            case .success():
                                print("Чек успешно загружен")
                                DispatchQueue.main.async {
                                    if generatedPDFURL != nil {
                                        navigationPath.removeLast(3)
                                    } else {
                                        navigationPath.removeLast(1)
                                    }
                                    
                                    generatedPDFURL = nil
                                    viewModel.selectedDocument = nil
                                    viewModel.selectedDocument = nil
                                    
                                    print("✅ Успех: файл не был отправлен, но JSON дошел!")
                                    
                                    viewModel.IsUploadInProcess = false
                                    
                                    capturedMediaDoc = []
                                    
                                }
                            
                            case .failure(let error):
                                
                                print("❌ Ошибка: \(error)")
                                
                                viewModel.IsUploadInProcess = false
                            }
                        }
                    }
                }
            }, label: {
                if viewModel.IsUploadInProcess {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(viewModel.fieldIsCorrect ? Colors.orange : Colors.textFieldOverlayGray)
                        .cornerRadius(16)
                        .padding(.bottom, 8)
                } else {
                    HStack {
                        Text("Загрузить чек")
                            .foregroundColor(Color.white)
                            .font(Fonts.Font_Headline2)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background((!viewModel.checkTypeString.isEmpty && !viewModel.nomenclatureString.isEmpty && !viewModel.documentPrice.isEmpty && !viewModel.documentName.isEmpty) ? Colors.orange : Colors.textFieldOverlayGray)
                    .cornerRadius(16)
                    .padding(.bottom, 8)
                }
            })
            .padding(.horizontal, 16)
        }
        .sheet(isPresented: $viewModel.showingDocumentPicker) {
            DocumentPicker(document: $viewModel.selectedDocument)
                .ignoresSafeArea()
        }
        .onAppear{
            print("tappedObjectId = \(viewModel.tappedObjectId) \(tappedObjectId)")
            viewModel.getAllNomenclatureId()
        }
        .onDisappear{
            viewModel.nomenclatureString = ""
            viewModel.checkTypeString = ""
            viewModel.documentPrice = ""
            viewModel.documentName = ""
        }
    }
}

struct TypeCheckSheet: View {
    @StateObject
    var viewModel: createCheckViewModel
    
    var body: some View {
        VStack {
            HStack{
                Text("Выберите тип")
                    .font(Font.custom("Roboto", size: 20).weight(.semibold))
                    .padding(.top, 24)
                
                Spacer()
            }
            ForEach(Array(viewModel.type.enumerated()), id: \.element) { index, text in
                Button(action: {
                    withAnimation {
                        viewModel.isOutcome = (text == "Расход") // Устанавливаем флаг в зависимости от выбора
                        viewModel.checkTypeString = text
                        print(viewModel.checkTypeString)
                        print(viewModel.isOutcome)
                        viewModel.checkTypeSheetShow = false
                    }
                }) {
                    HStack{
                        
                        if (text == "Расход") {
                            Image("rashod")
                        } else {
                            Image("dohod")
                        }
                        
                        Text(text)
                            .font(.headline)
                            .foregroundColor((text == "Расход") ? Colors.textFieldOverlayGray : Color.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .presentationDetents([.medium, .height(160)])
        .padding(.horizontal, 16)
    }
}

struct NomenclaturesSheet: View {
    
    @StateObject
    var viewModel: createCheckViewModel
    
    var body: some View {
        VStack {
            HStack{
                Text("Выберите номенклатуру")
                    .font(Font.custom("Roboto", size: 20).weight(.semibold))
                    .padding(.top, 24)
                
                Spacer()
            }
            ScrollView{
                ForEach(viewModel.nomenclatures, id: \.self) { nomen in
                    Button(action: {
                        withAnimation {
                            print(nomen.title)
                            viewModel.nomenclatureString = nomen.title
                            viewModel.selectednomenclatureId = nomen.nomenclatureId
                            viewModel.sheetNomenklatureTypeShown = false
                            
                        }
                    }) {
                        Text(nomen.title)
                            .font(.headline)
                            .foregroundColor(Color.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 16)
                }
            }
            
            Spacer()
        }
        .presentationDetents([.medium])
        .padding(.horizontal, 16)    }
}
