//
//  cameraStruct.swift
//  stroymir
//
//  Created by Корнеев Александр on 29.07.2024.
//


import SwiftUI
import AVFoundation

struct cameraStruct: View {
    
    @Binding var navigationPath: NavigationPath
    @Binding var capturedMedia: [CapturedMedia]
    @State private var isFlashOn = false // Для управления состоянием фонарика
    
    @State private var showMessage = false
    
    var body: some View {
        ZStack{
            CameraView(
                onMediaCaptured: { media in
                    if capturedMedia.count < 10 {
                        capturedMedia.append(media)
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
                 
                    ZStack{
                        Image("Group2608685")
                           
                        Text("Достигнут лимит медиа в отчете") //
                            .font(Fonts.Font_Callout)
                            .foregroundColor(.white)
                            .transition(.opacity)
                            .animation(.easeInOut)
                            .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 58)
                }
                
                HStack {
                    
                    Spacer()
                    
                    Button(action: {
                        if !capturedMedia.isEmpty {
                            navigationPath.append(Destination.druganddropreportsphoto)
                        }
                    }, label: {
                        HStack{
                            ZStack {
                                // Display captured images and videos
                                ForEach(Array(capturedMedia.suffix(1).enumerated()), id: \.element) { index, media in
                                    switch media {
                                    case .image(let image):
                                        Image(uiImage: image)
                                            .resizable()
                                            .frame(width: 48, height: 48)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .padding(1)
                                            .offset(x: CGFloat(index * 10), y: CGFloat(index * 10))
                                    case .video(let videoURL):
                                        VideoThumbnailViewPreview(videoURL: videoURL)
                                            .frame(width: 48, height: 48)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .padding(1)
                                            .offset(x: CGFloat(index * 10), y: CGFloat(index * 10))
                                    }
                                    
                                    Text("\(capturedMedia.count)")
                                        .foregroundColor(Color.white)
                                        .font(Fonts.Font_Callout)
                                        .frame(width: 18, height: 18)
                                        .background(Colors.orange)
                                        .cornerRadius(16)
                                        .padding(.leading, 48)
                                        .padding(.bottom, 48)
                                }
                            }
                           
                            if !capturedMedia.isEmpty{
                                Image("arrow_forward1")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(.bottom, 12)
                        .padding(.horizontal, 20)
                    })
                }
            }
        }
        .gesture(
            
            DragGesture()
                .onEnded { value in
                    // Проверяем, что жест начинается от левого края и перемещается вправо
                    if value.startLocation.x < 20 && value.translation.width > 100 {
                        // Если свайп идет вправо более чем на 100 пикселей
                        if navigationPath.count > 0 {
                            navigationPath.removeLast(1)
                        }
                    }
                }
        )
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

struct VideoThumbnailView: View {
    var videoURL: URL
    @State private var duration: Double = 0.0

    var body: some View {
        ZStack {
            if let thumbnailImage = generateThumbnail(url: videoURL) {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.black
            }
            VStack{
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Text(durationText)
                        .font(.caption)
                        .padding(2)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding([.top, .trailing, .leading], 4)
                }
            }
                Image(systemName: "play.circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                
                Spacer()
            
        }
        .onAppear {
            duration = getVideoDuration(url: videoURL)
        }
    }

    private var durationText: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func generateThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let cgImage = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    func getVideoDuration(url: URL) -> Double {
        let asset = AVAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }
}

struct VideoThumbnailViewPreview: View {
    var videoURL: URL
    @State private var duration: Double = 0.0

    var body: some View {
        ZStack {
            if let thumbnailImage = generateThumbnail(url: videoURL) {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.black
            }
                Image(systemName: "play.circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                
                Spacer()
            
        }
        .onAppear {
            duration = getVideoDuration(url: videoURL)
        }
    }

    private var durationText: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func generateThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let cgImage = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    func getVideoDuration(url: URL) -> Double {
        let asset = AVAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }
}

