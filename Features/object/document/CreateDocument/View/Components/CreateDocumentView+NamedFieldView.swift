//
//  CreateDocumentView+NamedFieldView.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 19.11.2024.
//

import SwiftUI

extension CreateDocumentVievNew {
    struct NamedFieldView<Content: View>: View {
    
        let title: String
        let content: () -> Content
        
        var body: some View {
            VStack(alignment: .leading, spacing: .vertcalSpacing) {
                Text(title)
                    .font(Fonts.Font_Callout)
                
                content()
                
            }
        }
    }
    struct SelectObjectType {
        
        
    }
}

private extension CGFloat {
    static let vertcalSpacing: Self = 8.0
}
