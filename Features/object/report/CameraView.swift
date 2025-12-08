//
//  CameraView.swift
//  stroymir
//
//  Created by Корнеев Александр on 23.07.2024.
//

import SwiftUI
import AVFoundation
import AVKit

enum CapturedMedia: Hashable {
    case image(UIImage)
    case video(URL)
}

struct CameraView: UIViewControllerRepresentable {
    var onMediaCaptured: (CapturedMedia) -> Void

    typealias UIViewControllerType = CameraViewController

    class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
        var captureSession: AVCaptureSession!
        var photoOutput: AVCapturePhotoOutput!
        var videoOutput: AVCaptureMovieFileOutput!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var captureButton: UIButton?
        var progressLayer: CAShapeLayer?
        var buttonBackgroundView: UIView?
        var shutterOverlay: UIView?  // Изменили на опциональный тип
        
        var onMediaCaptured: ((CapturedMedia) -> Void)?
        
        var recordingTimer: Timer?
        var recordingDuration: TimeInterval = 300.0
        var elapsedRecordingTime: TimeInterval = 0.0
        
        override func viewDidLoad() {
                   super.viewDidLoad()
            
            view.backgroundColor = .black
                   
                   // Запрашиваем разрешения
                   requestPermissions { [weak self] granted in
                       DispatchQueue.main.async {
                           if granted {
                               self?.setupCameraSession() // Настройка сессии камеры при наличии разрешений
                           } else {
                               self?.showPermissionDeniedAlert() // Показываем предупреждение об отсутствии разрешений
                           }
                       }
                   }
               }

               // Функция для запроса разрешений на доступ к камере и микрофону
               private func requestPermissions(completion: @escaping (Bool) -> Void) {
                   AVCaptureDevice.requestAccess(for: .video) { videoGranted in
                       guard videoGranted else {
                           completion(false)
                           return
                       }
                       
                       AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
                           completion(audioGranted)
                       }
                   }
               }

               // Настраиваем камеру и микрофон только при наличии разрешений
               private func setupCameraSession() {
                   captureSession = AVCaptureSession()
                   captureSession.sessionPreset = .photo

                   guard let backCamera = AVCaptureDevice.default(for: .video),
                         let microphone = AVCaptureDevice.default(for: .audio) else { return }

                   do {
                       let videoInput = try AVCaptureDeviceInput(device: backCamera)
                       let audioInput = try AVCaptureDeviceInput(device: microphone)

                       captureSession.addInput(videoInput)
                       captureSession.addInput(audioInput)

                       photoOutput = AVCapturePhotoOutput()
                       captureSession.addOutput(photoOutput)

                       videoOutput = AVCaptureMovieFileOutput()
                       captureSession.addOutput(videoOutput)

                       // Настройка слоя предварительного просмотра камеры
                       previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                       previewLayer.videoGravity = .resizeAspectFill
                       view.layer.addSublayer(previewLayer)
                       
                       captureSession.startRunning()
                       setupCaptureButton()
                   } catch {
                       print("Ошибка настройки камеры: \(error.localizedDescription)")
                   }
               }

               // Оповещение пользователя об отсутствии разрешений
               private func showPermissionDeniedAlert() {
                   let alert = UIAlertController(
                       title: "Доступ к камере и микрофону запрещен",
                       message: "Для записи медиа, перейдите в Настройки и разрешите доступ.",
                       preferredStyle: .alert
                   )
                   
                   alert.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
                   alert.addAction(UIAlertAction(title: "Открыть настройки", style: .default) { _ in
                       guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                       if UIApplication.shared.canOpenURL(settingsURL) {
                           UIApplication.shared.open(settingsURL)
                       }
                   })
                   
                   self.present(alert, animated: true, completion: nil)
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


        private func setupCaptureButton() {
            let buttonSize: CGFloat = 50
            let borderWidth: CGFloat = 4
            let bottomOffset: CGFloat = 50

            // Создаем подложку для кнопки
            buttonBackgroundView = UIView(frame: CGRect(x: (view.frame.width - buttonSize - borderWidth * 2) / 2, y: view.frame.height - buttonSize - borderWidth * 2 - bottomOffset, width: buttonSize + borderWidth * 2, height: buttonSize + borderWidth * 2))
            buttonBackgroundView?.backgroundColor = .white
            buttonBackgroundView?.layer.cornerRadius = (buttonSize + borderWidth * 2) / 2
            view.addSubview(buttonBackgroundView!)

            // Настраиваем кнопку захвата
            captureButton = UIButton(frame: CGRect(x: borderWidth, y: borderWidth, width: buttonSize, height: buttonSize))
            // Используем цвет из SwiftUI Color, преобразованный в UIColor
            let orangeColor = UIColor(Colors.orange)
            captureButton?.backgroundColor = orangeColor
            captureButton?.layer.cornerRadius = buttonSize / 2
            buttonBackgroundView?.addSubview(captureButton!)

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
            captureButton?.addGestureRecognizer(tapGesture)
            captureButton?.addGestureRecognizer(longPressGesture)

            // Добавляем прогресс-слой для записи видео
            setupProgressLayer(on: buttonBackgroundView!)

            // Перемещаем кнопку на передний план
            view.bringSubviewToFront(buttonBackgroundView!)
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
        
        private func setupProgressLayer(on view: UIView) {
            progressLayer = CAShapeLayer()
            guard let progressLayer = progressLayer else { return }
            let adjustedRadius = (view.bounds.width / 2) - (progressLayer.lineWidth / 2) - 1
            let circularPath = UIBezierPath(arcCenter: CGPoint(x: view.bounds.midX, y: view.bounds.midY), radius: adjustedRadius, startAngle: -CGFloat.pi / 2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
            
            progressLayer.path = circularPath.cgPath
            progressLayer.strokeColor = UIColor.red.cgColor
            progressLayer.fillColor = UIColor.clear.cgColor
            progressLayer.lineWidth = 5
            progressLayer.strokeEnd = 0
            view.layer.addSublayer(progressLayer)
        }

        @objc private func takePhoto() {
            animateCaptureButton()
            showShutterEffect()
            
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
        
        @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                startRecording()
            } else if gesture.state == .ended {
                stopRecording()
            }
        }
        
        private func startRecording() {
            let outputFilePath = NSTemporaryDirectory() + "\(UUID().uuidString).mov"
            let outputURL = URL(fileURLWithPath: outputFilePath)
            videoOutput.startRecording(to: outputURL, recordingDelegate: self)
            
            elapsedRecordingTime = 0.0
            progressLayer?.strokeEnd = 0.0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                self.elapsedRecordingTime += 0.1
                self.progressLayer?.strokeEnd = CGFloat(self.elapsedRecordingTime / self.recordingDuration)
                if self.elapsedRecordingTime >= self.recordingDuration {
                    self.stopRecording()
                }
            }
        }
        
        private func stopRecording() {
            videoOutput.stopRecording()
            recordingTimer?.invalidate()
            progressLayer?.strokeEnd = 0.0
        }
        
        private func animateCaptureButton() {
            UIView.animate(withDuration: 0.1, animations: {
                self.captureButton?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    self.captureButton?.transform = CGAffineTransform.identity
                }
            }
        }
        
        private func showShutterEffect() {
            // Проверка на инициализацию shutterOverlay
            guard let shutterOverlay = shutterOverlay else { return }
            
            UIView.animate(withDuration: 0.1, animations: {
                shutterOverlay.alpha = 1.0
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    shutterOverlay.alpha = 0.0
                }
            }
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else { return }
            
            onMediaCaptured?(.image(image))
        }
        
        func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            if let error = error {
                print("Error recording video: \(error.localizedDescription)")
                return
            }
            
            onMediaCaptured?(.video(outputFileURL))
        }
    }
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.onMediaCaptured = onMediaCaptured
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

