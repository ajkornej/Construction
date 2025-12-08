//
//  CreateDocumentView.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 19.11.2024.
//

import SwiftUI

struct CreateDocumentVievNew: View {

    @ObservedObject
    var viewModel: CreateDocumentViewModel
    
    var body: some View {
        
        NamedFieldView(title: "Название") {
            TextField("",text: $viewModel.documentName, prompt: Text("Введите название").foregroundColor(Colors.textFieldOverlayGray))
                .autocapitalization(.none)
                .foregroundColor(.black)
                .disableAutocorrection(true)
                .textContentType(.emailAddress)
                .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                .overlay(RoundedRectangle(cornerRadius: 18).inset(by: 1).stroke(!viewModel.documentName.isEmpty ? Colors.textFieldOverlayGray : Color.red))
                .cornerRadius(18)
        }
    }
}

#Preview {
    CreateDocumentVievNew(viewModel: .init())
}
