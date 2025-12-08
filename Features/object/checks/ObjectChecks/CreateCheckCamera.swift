//
//  CreateCheckCamera.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 11.02.2025.
//

import SwiftUI
import AVFoundation
import AVKit

//struct CreateCheckCamera: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}


struct CreateCheckCamera: View {
    
    @Binding var navigationPath: NavigationPath
    @Binding var capturedMediaDoc: [CapturedMediaDocument]
    
    @State private var isFlashOn = false 
    
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
            .toolbar {
                // Текстовое поле слева
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        navigationPath.removeLast(1)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 17, weight: .medium)) // Размер и стиль стрелки
                            Text("Назад")
                                .font(.system(size: 17)) // Размер текста
                        }
                        .foregroundColor(.white) // Цвет текста и иконки
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                    Button(action: {
                        toggleFlashlight() // Включаем/выключаем фонарик
                    }) {
                        Image("flashlight_on_FILL0_wght400_GRAD0_opsz24 1")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            
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
                            navigationPath.append(Destination.druganddropcheck)
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
    func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
                isFlashOn = false
            } else {
                try device.setTorchModeOn(level: 1.0)
                isFlashOn = true
            }
            device.unlockForConfiguration()
        } catch {
            print("Error while toggling flashlight: \(error)")
        }
    }
}




