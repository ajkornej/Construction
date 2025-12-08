//
//  openObjectCamera.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 03.12.2024.
//


    import SwiftUI
    import AVFoundation
    import AVKit

    struct openObjectCamera: View {
        
        @Binding var navigationPath: NavigationPath
        @Binding var capturedMediaDoc: [CapturedMediaDocument]
        
        @State private var showMessage = false
        
        var body: some View {
            ZStack {
                CameraStructDocuments(
                    onMediaCaptured: { media in
                        if capturedMediaDoc.count < 10 {
                            capturedMediaDoc.append(media)
                        } else {
                            showMessage = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showMessage = false
                            }
                        }
                    }
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    if showMessage {
                        ZStack {
                            Image("Group2608685")
                            Text("Достигнут лимит медиа в отчете")
                                .font(Fonts.Font_Callout)
                                .foregroundColor(.white)
                                .transition(.opacity)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 58)
                    }
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            if !capturedMediaDoc.isEmpty {
                                navigationPath.append(Destination.openObjectDrugAndDropDocument)
                            }
                        }, label: {
                            HStack {
                                ZStack {
                                    // Display last captured image
                                    if let lastMedia = capturedMediaDoc.last, case let .image(image) = lastMedia {
                                        Image(uiImage: image)
                                            .resizable()
                                            .frame(width: 48, height: 48)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .padding(1)
                                    }
                                    
                                    // Count badge
                                    if !capturedMediaDoc.isEmpty {
                                        Text("\(capturedMediaDoc.count)")
                                            .foregroundColor(Color.white)
                                            .font(Fonts.Font_Callout)
                                            .frame(width: 18, height: 18)
                                            .background(Colors.orange)
                                            .cornerRadius(16)
                                            .padding(.leading, 48)
                                            .padding(.bottom, 48)
                                    }
                                }
                                
                                if !capturedMediaDoc.isEmpty {
                                    Image("arrow_forward1")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                }
                            }
                            .padding(.bottom, 12)
                            .padding(.horizontal, 16)
                        })
                    }
                }
            }
        }
    }




