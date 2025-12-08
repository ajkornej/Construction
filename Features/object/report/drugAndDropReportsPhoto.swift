//
//  drugAndDropReportsPhoto.swift
//  stroymir
//
//  Created by Корнеев Александр on 29.07.2024.
//

import SwiftUI
import UniformTypeIdentifiers

enum UploadStatus {
    case loading
    case success
    case failure
}

struct MediaUploadState {
    var media: CapturedMedia
    var status: UploadStatus
}


struct drugAndDropReportsPhoto: View {
    
    
    @Binding var navigationPath: NavigationPath
    @Binding var capturedMedia: [CapturedMedia]
    
    @State private var dragItem: CapturedMedia?
    @State var description: String = ""
    @Binding var tappedObjectId: String
    
    @State var descriptionEmpty: Bool = false

    @StateObject var viewModel = ObjectPhotosViewModel()
    @State var descriptionCount: String = "0"
    @State var descriptionCountValid: Bool = true

    @State var loading: Bool = false
    @State var mediaStates: [MediaUploadState] = []

    var body: some View {
        VStack {
            Text("Описание")
                .font(Fonts.Font_Callout)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.top, 12)
                .padding(.horizontal, 16)
            
            
            ResizableTextEditor(text: $description, descriptionEmpty: $descriptionEmpty, descriptionCountValid: $descriptionCountValid, descriptionCount: $descriptionCount)

           
            Text("\(descriptionCount)/250")
                .font(Fonts.Font_Footnote)
                .foregroundColor(!descriptionCountValid ? Color.red : Colors.textFieldOverlayGray)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 1)
                .padding(.horizontal, 16)
            
             
            ScrollView {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 8) {
                    ForEach(capturedMedia, id: \.self) { item in
                        ZStack {
                            switch item {
                            case .image(let image):
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 84) // Ширина для формата 4:3
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                                
                            case .video(let url):
                                if !loading {
                                    VideoThumbnailView(videoURL: url)
                                        .scaledToFit()
                                        .frame(width: 84)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .cornerRadius(12)
                                        .shadow(radius: 5)
                                }
                            }
                            // Добавляем индикатор загрузки, если файл в процессе загрузки
                            if let mediaState = mediaStates.first(where: { $0.media == item }) {
                                VStack {
                                    if mediaState.status == .loading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                            .scaleEffect(1.5)
                                            .frame(width: 60, height: 60) // Увеличиваем размер еще больше
                                    } else if mediaState.status == .failure {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.red)
                                    } else if mediaState.status == .success {
                                        Image(systemName: "checkmark.gobackward")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(8)
                            }
                            
                            VStack{
                                HStack{
                                    Spacer()
                                    Button(action: {
                                        if let index = capturedMedia.firstIndex(of: item) {
                                            withAnimation {
                                                capturedMedia.remove(at: index)
                                                if capturedMedia.isEmpty {
                                                    navigationPath.removeLast(1)
                                                }
                                            }
                                        }
                                    }) {
                                        Image("cancel")
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                            .foregroundColor(.orange)
                                            .padding(.top, 4)
                                            .padding(.trailing, 8)
                                        
                                    }
                                }
                                Spacer()
                            }
                        }
                        .onDrag {
                            self.dragItem = item
                            return NSItemProvider(object: "\(item)" as NSString)
                        }
                        .onDrop(of: [UTType.text], delegate: DropViewDelegate(item: item, items: $capturedMedia, dragItem: $dragItem))
                    }
                }
                .padding(.horizontal, 16)
                .animation(.easeInOut, value: capturedMedia)
            }
            Spacer()
            
            Button(
                action: {
                    if description != "" && descriptionCountValid && !loading {
                        print("tapped")
                        handleUpload()
                    } else {
                        descriptionEmpty = true
                    }
                },
                label: {
                    if loading {
                        ProgressView()
                            .foregroundColor(Color.white)
                            .font(Fonts.Font_Headline2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background((description != "" && descriptionCountValid) ? Colors.orange : Colors.textFieldOverlayGray)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    } else {
                        Text("Сформировать отчёт")
                            .foregroundColor(Color.white)
                            .font(Fonts.Font_Headline2)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background((description != "" && descriptionCountValid) ? Colors.orange : Colors.textFieldOverlayGray)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                })
        }
        .navigationBarTitle("Новый отчёт")
        .onTapGesture {
           hideKeyboard()
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // функция которая возвращает этот массив
    func getCapturedMedia() -> [CapturedMedia] {
        return capturedMedia
    }
    
    func uploadReport(objectId: String, serverFilenames: [String], comment: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(AppConfig.baseURL)reports") else {
            print("Invalid URL")
            return
        }
        
        loading = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AccessTokenHolder.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Проверяем что массив serverFilenames не пустой и не содержит null значений
        guard !serverFilenames.isEmpty else {
            print("serverFilenames array is empty or contains null values")
            completion(.failure(NSError(domain: "UploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "serverFilenames array is empty or contains null values"])))
            return
        }
        
        // Формируею JSON
        let report: [String: Any] = [
            "objectId": objectId,
            "filenames": serverFilenames.map { filenameJSON in
                guard let data = filenameJSON.data(using: .utf8),
                      let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let filename = jsonObject["filename"] as? String else {
                    return filenameJSON // Если парсинг не удался, оставляем исходное значение
                }
                return filename
            },
            "comment": comment
        ]

        print(serverFilenames)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: report, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Payload being sent to server: \(jsonString)")
            }
            request.httpBody = jsonData
        } catch {
            print("Error serializing JSON: \(error)")
        }

        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: report, options: [])
            request.httpBody = jsonData
            
            // Выполняем запрос
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    print("Failed to upload report with filenames: \(serverFilenames)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Full server response: \(httpResponse)")

                    print("Status code: \(httpResponse.statusCode)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Response: \(responseString)")
                    }
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        let statusError = NSError(domain: "com.example.upload", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unexpected server response: \(httpResponse.statusCode)"])
                        completion(.failure(statusError))
                        return
                    }
                    
                }
                
                completion(.success(()))
            }
            
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }

    func handleUpload() {
        loading = true
        let capturedMedia: [CapturedMedia] = getCapturedMedia()
        
        // Удаляем параметр mediaStates, т.к. он инициализируется внутри uploadMediaFiles
        uploadMediaFiles(capturedMedia: capturedMedia) { serverFilenames in
            guard let serverFilenames = serverFilenames else {
                DispatchQueue.main.async {
                    self.loading = false
                }
                return
            }
            
            uploadReport(objectId: tappedObjectId, serverFilenames: serverFilenames, comment: description) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        navigationPath.removeLast(2)
                    case .failure(let error):
                        print("Error: \(error)")
                    }
                    self.loading = false
                }
            }
        }
    }

    // Функция загрузки одного файла
    func uploadFile(_ filePath: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(AppConfig.baseURL)files") else {
            print("Invalid URL")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = AccessTokenHolder.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) {
            let filename = (filePath as NSString).lastPathComponent
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        }

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("File upload failed: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received from file upload")
                completion(nil)
                return
            }

            // Парсим JSON ответ сервера
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let filename = json["filename"] as? String {
                    completion(filename)
                } else {
                    print("Invalid response format")
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON response: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }

    func uploadMediaFiles(capturedMedia: [CapturedMedia], completion: @escaping ([String]?) -> Void) {
        // Инициализируем mediaStates, устанавливая всем элементам статус .loading
        DispatchQueue.main.async {
            self.mediaStates = capturedMedia.map { MediaUploadState(media: $0, status: .loading) }
        }
        
        // Запускаем последовательную загрузку с первого элемента
        uploadSequentially(index: 0, mediaList: capturedMedia, uploadedFiles: [], completion: completion)
    }
    
    func uploadSequentially(index: Int, mediaList: [CapturedMedia], uploadedFiles: [String], completion: @escaping ([String]?) -> Void) {
        // Если все файлы обработаны, вызываем completion с результатами
        if index >= mediaList.count {
            completion(uploadedFiles.isEmpty ? nil : uploadedFiles)
            return
        }
        
        let media = mediaList[index]
        
        // Статус уже установлен в .loading при инициализации в uploadMediaFiles,
        // поэтому здесь дополнительно его менять не нужно перед началом загрузки
        
        switch media {
        case .image(let image):
            if let filePath = saveImageToTemporaryDirectory(image) {
                uploadFile(filePath) { response in
                    DispatchQueue.main.async {
                        if let response = response {
                            var newUploadedFiles = uploadedFiles
                            newUploadedFiles.append(response)
                            self.mediaStates[index].status = .success
                            // Переходим к следующему файлу с обновленным списком
                            self.uploadSequentially(index: index + 1, mediaList: mediaList, uploadedFiles: newUploadedFiles, completion: completion)
                        } else {
                            self.mediaStates[index].status = .failure
                            // Продолжаем с текущим списком, не добавляя ничего
                            self.uploadSequentially(index: index + 1, mediaList: mediaList, uploadedFiles: uploadedFiles, completion: completion)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.mediaStates[index].status = .failure
                    self.uploadSequentially(index: index + 1, mediaList: mediaList, uploadedFiles: uploadedFiles, completion: completion)
                }
            }
            
        case .video(let url):
            uploadFile(url.path) { response in
                DispatchQueue.main.async {
                    if let response = response {
                        var newUploadedFiles = uploadedFiles
                        newUploadedFiles.append(response)
                        self.mediaStates[index].status = .success
                        self.uploadSequentially(index: index + 1, mediaList: mediaList, uploadedFiles: newUploadedFiles, completion: completion)
                    } else {
                        self.mediaStates[index].status = .failure
                        self.uploadSequentially(index: index + 1, mediaList: mediaList, uploadedFiles: uploadedFiles, completion: completion)
                    }
                }
            }
        }
    }

    // Функция для сохранения изображения в временную директорию и получения пути
    func saveImageToTemporaryDirectory(_ image: UIImage) -> String? {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        if let imageData = image.jpegData(compressionQuality: 1.0) {
            do {
                try imageData.write(to: fileURL)
                return fileURL.path // Возвращаем путь к файлу
            } catch {
                print("Error saving image to temporary directory: \(error)")
            }
        }
        return nil
    }

}


struct DropViewDelegate: DropDelegate {
    let item: CapturedMedia
    @Binding var items: [CapturedMedia]
    @Binding var dragItem: CapturedMedia?

    func performDrop(info: DropInfo) -> Bool {
        guard let dragItem = dragItem else { return false }
        guard let fromIndex = items.firstIndex(of: dragItem),
              let toIndex = items.firstIndex(of: item) else { return false }

        // Обновляем массив данных с анимацией
        withAnimation {
            items.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
        
        self.dragItem = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

struct ResizableTextEditor: View {
    @Binding var text: String
    @State private var textViewHeight: CGFloat = 100 // Изначальная высота для одной строки
    @Binding var descriptionEmpty: Bool
    @Binding var descriptionCountValid: Bool
    @Binding var descriptionCount: String
    @State var redAlert: Bool = false
  
    // Для отслеживания фокуса
    @FocusState private var isFocused: Bool
    
    var body: some View {
        
        ZStack(alignment: .topLeading) {

           // Сам TextEditor
           TextEditor(text: $text)
               .frame(minHeight: textViewHeight, maxHeight: textViewHeight)
               .foregroundColor(.black)
               .accentColor(Colors.orange)
               .padding(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 32))
               .overlay(
                   RoundedRectangle(cornerRadius: 18)
                       .inset(by: 1)
                       .stroke(
                           // Изменение цвета обводки в зависимости от фокуса и валидации
                           isFocused && (!descriptionEmpty && descriptionCountValid) ? Color.orange :
                           (!descriptionEmpty && descriptionCountValid) ? Colors.textFieldOverlayGray : Color.red)
               )
               .cornerRadius(18)
               .padding(.horizontal, 16)
               .focused($isFocused)
               .onChange(of: text) { newValue in
                   descriptionCount = String(newValue.count)
                   // Обновление флагов валидации
                   descriptionEmpty = newValue.isEmpty
                   descriptionCountValid = newValue.count <= 250
                   // Пересчитываем высоту поля
//                   recalculateHeight()
               }
               .onAppear{
                   isFocused = true
               }
            
            if text.isEmpty {
                Text("Введите описание")
                    .foregroundStyle(Colors.textFieldOverlayGray)
                    .padding(.top, 42)
                    .padding(.horizontal, 36)
                    .frame(height: 10)
                    .allowsHitTesting(false)
            }
            
            if text != "" {
                Button(action: {
                    text = ""
                }, label: {
                    if descriptionCountValid {
                        Image("close")
                            .resizable()
                            .frame(width: 24, height: 24)
                    } else {
                        Image("close_red")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                })
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 30)
                .padding(.top, 16)
            }
        }
        .onTapGesture {
           hideKeyboard()
        }
    }
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func recalculateHeight() {
        // Определяем высоту текста с помощью NSString
        let size = CGSize(width: UIScreen.main.bounds.width - 64, height: .infinity)
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        let estimatedSize = NSString(string: text).boundingRect(
            with: size,
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )
        
        // Минимальная высота для одной строки, а максимальная — на основе текста
        textViewHeight = max(40, estimatedSize.height + 32) // Минимум 40 для одной строки
    }
}

//
//// Затемнение и лоадер
//if loadingStates[item] == true {
//    Color.black.opacity(0.6)
//        .frame(width: 84) // Ширина для формата 4:3
//        .cornerRadius(12) // Применение того же радиуса, что и для контента
//        .clipShape(RoundedRectangle(cornerRadius: 12)) // Добавляем обрезку формы
//    ProgressView()
//        .foregroundColor(.white)
//}
