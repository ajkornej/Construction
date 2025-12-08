import Foundation
import SwiftUI
import MapboxMaps

struct MapboxMapView: UIViewRepresentable {
    
    private let mapStyleURI = "mapbox://styles/kozlovskiy/cluu8yhm1003o01p55d6t0sqb"
    
    @Binding var dataResponseObjectAll: [ObjectResponse]
    @Binding var tappedObjectId: String
    @Binding var navigationPath: NavigationPath
    @Binding var selectedObject: ObjectResponse
    @Binding var authResponse: AuthenticationResponse?
    
    func makeUIView(context: Context) -> MapView {
        let mapInitOptions = MapInitOptions()
        let mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)
        
        // Сохранение менеджера аннотаций в координаторе
        context.coordinator.pointAnnotationManager = mapView.annotations.makePointAnnotationManager()

        // Загрузка стиля карты
        if let styleURL = URL(string: mapStyleURI), let styleURI = StyleURI(url: styleURL) {
            mapView.mapboxMap.loadStyle(styleURI)
        } else {
            print("Invalid style URL")
        }
        
        if let savedCameraStateData = UserDefaults.standard.data(forKey: "mapCameraState"),
           let savedCameraState = try? JSONDecoder().decode(CameraState.self, from: savedCameraStateData) {
            let cameraOptions = CameraOptions(center: savedCameraState.center, zoom: savedCameraState.zoom)
            mapView.camera.ease(to: cameraOptions, duration: 0)
        }
        
        // Установка начальной позиции камеры
        let centerCoordinate = CLLocationCoordinate2D(latitude: 55.7318, longitude: 37.6173)
        mapView.mapboxMap.setCamera(to: CameraOptions(center: centerCoordinate, zoom: 10))
        
        // Скрытие элементов оформления на карте
        hideOrnaments(mapView: mapView)
        
        // Обновление аннотаций
        updateAnnotations(mapView: mapView, coordinator: context.coordinator)
        
        // Сохранение ссылки на mapView в координаторе
        context.coordinator.mapView = mapView
        
        // Создание кнопки для фокусировки на аннотациях
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "my_location")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 25
        button.layer.borderColor = Colors.orange.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = false // Важно для того, чтобы тень была видна

        // Добавляем тень на кнопку
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1 // Прозрачность тени
        button.layer.shadowOffset = CGSize(width: 0, height: 1) // Смещение тени
        button.layer.shadowRadius = 4 // Радиус размытия тени

        mapView.addSubview(button)

        // Добавление constraints для кнопки
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -50),
            button.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            button.widthAnchor.constraint(equalToConstant: 50),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Действие кнопки
        button.addTarget(context.coordinator, action: #selector(context.coordinator.centerCameraOnAnnotations), for: .touchUpInside)
        
      
        
        return mapView
    }

    func updateUIView(_ mapView: MapView, context: Context) {
        
        if (authResponse?.permissions.contains("READ_OBJECTS") ?? false) /*|| authResponse?.user.isEmployee == false*/ {
            // Обновляем аннотации с передачей координатора
            updateAnnotations(mapView: mapView, coordinator: context.coordinator)
        }
    }
    
    func onDisappear(mapView: MapView) {
        let cameraState = mapView.mapboxMap.cameraState
        let encodedData = try? JSONEncoder().encode(cameraState)
        UserDefaults.standard.set(encodedData, forKey: "mapCameraState")
    }
    
    private func hideOrnaments(mapView: MapView) {
        mapView.ornaments.options.logo.margins = .init(x: -10000, y: 0)
        mapView.ornaments.options.attributionButton.margins = .init(x: -10000, y: 0)
        mapView.ornaments.options.scaleBar.visibility = .hidden
        mapView.ornaments.options.compass.visibility = .hidden
    }
    
    private func updateAnnotations(mapView: MapView, coordinator: Coordinator) {
        let pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        
        var annotations: [PointAnnotation] = []
        
        for responseObject in dataResponseObjectAll {
            print("Статус объекта \(responseObject.objectId): \(responseObject.status)")
            
            let coordinate = CLLocationCoordinate2DMake(responseObject.latitude, responseObject.longitude)
            
            // Здесь создаем новую аннотацию для каждого объекта
            var pointAnnotation = PointAnnotation(coordinate: coordinate)
            
            // Логика определения цвета аннотации на основе статуса и флагов
            if responseObject.status == "IN_PROGRESS" {
                if responseObject.reportExpired {
                    if retrieveIsEmployee() {
                        pointAnnotation.image = .init(image: UIImage(named: "Ellipse_red")!, name: "Point Annotation \(responseObject.objectId)")
                    } else {
                        pointAnnotation.image = .init(image: UIImage(named: "Ellipse_blue")!, name: "Point Annotation \(responseObject.objectId)")
                    }
                } else {
                    pointAnnotation.image = .init(image: UIImage(named: "Ellipse_blue")!, name: "Point Annotation \(responseObject.objectId)")
                }
            } else if responseObject.status == "NEW" {
                pointAnnotation.image = .init(image: UIImage(named: "Ellipse_green")!, name: "Point Annotation \(responseObject.objectId)")
            } else if responseObject.status == "ARCHIVE" {
                pointAnnotation.image = .init(image: UIImage(named: "Ellipse_gray")!, name: "Point Annotation \(responseObject.objectId)")
            } else {
                pointAnnotation.image = .init(image: UIImage(named: "Ellipse_red")!, name: "Point Annotation \(responseObject.objectId)")
            }
            
            pointAnnotation.iconAnchor = .center
            pointAnnotation.userInfo = ["objectId": responseObject.objectId]
            
            // Обработка нажатия на аннотацию
            pointAnnotation.tapHandler = { context in
                if let selected = dataResponseObjectAll.first(where: { $0.objectId == responseObject.objectId }) {
                    selectedObject = selected
                    tappedObjectId = responseObject.objectId
                    navigationPath.append(Destination.objectDetails) // Выполняем навигацию
                    return true
                }
                return false
            }
            
            // Добавляем каждую аннотацию в массив
            annotations.append(pointAnnotation)
        }
        
        // Присваиваем все аннотации менеджеру
        pointAnnotationManager.annotations = annotations
        
        // Проверяем количество аннотаций
        if annotations.count > 1 /*|| (annotations.count == 1 && coordinator.isButtonTapped)*/ {
            var coordinates: [CLLocationCoordinate2D] = annotations.map { $0.point.coordinates }
            coordinates.append(coordinates.first!) // Закрываем полигон
            
            let polygon = Polygon([coordinates])
            let edgeInsets = UIEdgeInsets(top: 120, left: 100, bottom: 120, right: 100)
            let cameraOptions = mapView.mapboxMap.camera(for: .polygon(polygon), padding: edgeInsets, bearing: nil, pitch: nil)
            mapView.camera.ease(to: cameraOptions, duration: 2.0, curve: .easeInOut, completion: nil)
            
            // Сохраняем последнее состояние камеры
            coordinator.lastCameraState = mapView.mapboxMap.cameraState
        }
        if annotations.count == 1 {
            coordinator.pendingTask?.cancel() // Отмена предыдущей задачи
            let coordinate = annotations[0].point.coordinates
            let cameraOptions = CameraOptions(
                center: coordinate,
                zoom: 15 // Устанавливаем фиксированный зум
            )
            mapView.camera.ease(to: cameraOptions, duration: 3.5)
  
            tappedObjectId = dataResponseObjectAll[0].objectId
           
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                if !coordinator.hasAppeared {
                    coordinator.hasAppeared = true // Устанавливаем флаг
                    navigationPath.append(Destination.objectDetails)
                }
            }
            coordinator.pendingTask?.cancel()
        }
        if annotations.count == 0 {
            let centerCoordinate = CLLocationCoordinate2D(latitude: 55.7318, longitude: 37.6173)
            let cameraOptions = CameraOptions(
                center: centerCoordinate,
                zoom: 10 // Устанавливаем фиксированный зум
            )
            mapView.camera.ease(to: cameraOptions, duration: 1.5)
        }
    }

    class Coordinator: NSObject {
        var parent: MapboxMapView
        var mapView: MapView? // Хранение ссылки на mapView
        var pointAnnotationManager: PointAnnotationManager? // Хранение менеджера аннотаций
        var lastCameraState: CameraState? // Сохраняем последнее состояние камеры после зума
        var isButtonTapped: Bool = false // Флаг для отслеживания нажатия кнопки
        var pendingTask: DispatchWorkItem?
        var hasAppeared = false

        init(parent: MapboxMapView) {
            self.parent = parent
        }
        
        @objc func centerCameraOnAnnotations() {
            isButtonTapped = true // Устанавливаем флаг при нажатии на кнопку
            if let mapView = mapView {
                // Вызываем updateAnnotations без передачи context
                parent.updateAnnotations(mapView: mapView, coordinator: self)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func retrieveIsEmployee() -> Bool {
        return UserDefaults.standard.bool(forKey: "isEmployee")
    }
}
