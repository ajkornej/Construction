//
//  CameraStructDocuments.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 17.09.2024.
//

import SwiftUI
import AVFoundation
import AVKit

enum CapturedMediaDocument: Hashable {
    case image(UIImage)
}

struct CameraStructDoc: View {
    
    @Binding var navigationPath: NavigationPath
    @Binding var capturedMediaDoc: [CapturedMediaDocument]
    
    @State private var showMessage = false
    
    @State private var isFlashOn = false // Для управления состоянием фонарика
    
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
                            navigationPath.append(Destination.drugAnddropdocument)
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

struct CameraStructDocuments: UIViewControllerRepresentable {
    var onMediaCaptured: (CapturedMediaDocument) -> Void

    class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
        var captureSession: AVCaptureSession!
        var photoOutput: AVCapturePhotoOutput!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var captureButton: UIButton!
        var buttonBackgroundView: UIView!
        var shutterOverlay: UIView!
        
        var onMediaCaptured: ((CapturedMediaDocument) -> Void)?
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            captureSession = AVCaptureSession()
            captureSession.sessionPreset = .high
            
            guard let backCamera = AVCaptureDevice.default(for: .video) else { return }
            let input = try! AVCaptureDeviceInput(device: backCamera)
            captureSession.addInput(input)
            
            photoOutput = AVCapturePhotoOutput()
            captureSession.addOutput(photoOutput)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            
            let buttonSize: CGFloat = 50
            let borderWidth: CGFloat = 4
            let bottomOffset: CGFloat = 50

            // Подложка для кнопки
            buttonBackgroundView = UIView(frame: CGRect(x: (view.frame.width - buttonSize - borderWidth * 2) / 2, y: view.frame.height - buttonSize - borderWidth * 2 - bottomOffset, width: buttonSize + borderWidth * 2, height: buttonSize + borderWidth * 2))
            buttonBackgroundView.backgroundColor = .white
            buttonBackgroundView.layer.cornerRadius = (buttonSize + borderWidth * 2) / 2
            view.addSubview(buttonBackgroundView)
            
            // Настраиваем кнопку
            captureButton = UIButton(frame: CGRect(x: borderWidth, y: borderWidth, width: buttonSize, height: buttonSize))
            let orangeColor = UIColor(Colors.orange)
            captureButton?.backgroundColor = orangeColor
            captureButton.layer.cornerRadius = buttonSize / 2
            buttonBackgroundView.addSubview(captureButton)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
            captureButton.addGestureRecognizer(tapGesture)
            
            // Shutter overlay
            shutterOverlay = UIView(frame: view.bounds)
            shutterOverlay.backgroundColor = UIColor.black
            shutterOverlay.alpha = 0.0
            view.addSubview(shutterOverlay)
            
            captureSession.startRunning()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            guard let previewLayer = previewLayer else {
                // Если previewLayer не существует, просто выходим из метода
                return
            }

            // Вычисляем размеры с соотношением 3:4
            let screenWidth = view.bounds.width
            let cameraHeight = screenWidth * 4 / 3  // Высота камеры при соотношении 3:4
            let yOffset = (view.bounds.height - cameraHeight) / 2  // Расчет отступа для черных полос

            // Устанавливаем фрейм с соотношением 3:4
            previewLayer.frame = CGRect(x: 0, y: yOffset, width: screenWidth, height: cameraHeight)

            // Черные полосы сверху и снизу
            let topBlackView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: yOffset))
            topBlackView.backgroundColor = .black
            view.addSubview(topBlackView)

            let bottomBlackView = UIView(frame: CGRect(x: 0, y: cameraHeight + yOffset, width: screenWidth, height: yOffset))
            bottomBlackView.backgroundColor = .black
            view.addSubview(bottomBlackView)

            // Обновляем расположение кнопки
            updateCaptureButtonPosition()

            // Убедимся, что кнопка всегда сверху
            if let buttonBackgroundView = buttonBackgroundView {
                view.bringSubviewToFront(buttonBackgroundView)
            }
        }
        
        private func updateCaptureButtonPosition() {
            let buttonSize: CGFloat = 50
            let borderWidth: CGFloat = 4
            let bottomOffset: CGFloat = 50

            // Проверка, чтобы кнопка и подложка были инициализированы
            if let buttonBackgroundView = buttonBackgroundView, let captureButton = captureButton {
                buttonBackgroundView.frame = CGRect(x: (view.frame.width - buttonSize - borderWidth * 2) / 2, y: view.frame.height - buttonSize - borderWidth * 2 - bottomOffset, width: buttonSize + borderWidth * 2, height: buttonSize + borderWidth * 2)
                captureButton.frame = CGRect(x: borderWidth, y: borderWidth, width: buttonSize, height: buttonSize)
            }
        }
        
        @objc func takePhoto() {
            animateCaptureButton()
            showShutterEffect()
            
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        func animateCaptureButton() {
            UIView.animate(withDuration: 0.1, animations: {
                self.captureButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    self.captureButton.transform = CGAffineTransform.identity
                }
            }
        }
        
        func showShutterEffect() {
            UIView.animate(withDuration: 0.1, animations: {
                self.shutterOverlay.alpha = 1.0
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    self.shutterOverlay.alpha = 0.0
                }
            }
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else { return }
            
            onMediaCaptured?(.image(image))
        }
    }
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.onMediaCaptured = onMediaCaptured
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
}






//#Preview {
//    CameraStructDocuments()
//}

//
//    .toolbar {
//        // Текстовое поле слева
//        ToolbarItem(placement: .navigationBarLeading) {
//            Button(action: {
//                navigationPath.removeLast(1)
//            }) {
//                HStack(spacing: 5) {
//                    Image(systemName: "chevron.backward")
//                        .font(.system(size: 17, weight: .medium)) // Размер и стиль стрелки
//                    Text("Назад")
//                        .font(.system(size: 17)) // Размер текста
//                }
//                .foregroundColor(.white) // Цвет текста и иконки
//            }
//        }
//        
//        ToolbarItem(placement: .navigationBarTrailing) {
//            
//            Button(action: {
//                toggleFlashlight() // Включаем/выключаем фонарик
//            }) {
//                Image("flashlight_on_FILL0_wght400_GRAD0_opsz24 1")
//                    .resizable()
//                    .frame(width: 24, height: 24)
//                    .foregroundColor(.white)
//                    .padding()
//            }
//        }
//    }
