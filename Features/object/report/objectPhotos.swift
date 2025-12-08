//
//  objectPhotos.swift
//  stroymir
//
//  Created by Корнеев Александр on 22.05.2024.
//


import SwiftUI
import AVKit
import Kingfisher
import KeychainSwift

private func formattedDate(from timestamp: Int) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ru_RU") // Устанавливаем локаль на русскую
    dateFormatter.dateFormat = "dd MMM HH:mm"
    return dateFormatter.string(from: date)
}

struct objectPhotos: View {
    @Binding var tappedObjectId: String
    @Binding var medias: [Media]
    @StateObject var viewModel = ObjectPhotosViewModel()
    @State private var selectedMedia: Media? = nil
    @State private var selectedMediaIndex: Int = 0
    @State private var showGallery: Bool = false
    @State var mediasReports: [Media] = []
    @Binding var navigationPath: NavigationPath
    @State var mediaComment: String = ""
    @State private var imageLoaded: [Int: Bool] = [:]
    @Binding var authResponse: AuthenticationResponse?
    @Binding var selectedObject: ObjectResponse

    var body: some View {
        VStack {
            ZStack {
                if viewModel.isFirstLoadComplete && viewModel.reports.isEmpty {
                    ProgressView()
                        .padding(.top, 32)
                } else if viewModel.reports.isEmpty && !viewModel.isLoadingPhoto {
                    EmptyStateView()
                } else {
                    ContentScrollView
                }

                if authResponse?.permissions.contains("READ_REPORTS") == true && selectedObject.status == "IN_PROGRESS" {
                    AddReportButton
                }
            }
        }
        .onAppear {
            print("onAppear вызван, проверяем needReload...")
            // Сбрасываем данные при каждом появлении экрана
            viewModel.resetPagination()
            viewModel.loadMedias(for: tappedObjectId)
        }
        .fullScreenCover(isPresented: $showGallery) {
            MediaGalleryView(medias: mediasReports, selectedIndex: $selectedMediaIndex, mediasReports: $mediasReports, mediaComment: $mediaComment, showGallery: $showGallery)
        }
    }

    private var ContentScrollView: some View {
        ScrollView {
            LazyVStack {
                ForEach(Array(viewModel.reports.enumerated()), id: \.element.reportId) { index, report in
                    MediaReportView(report: report,
                                    selectedMediaIndex: $selectedMediaIndex,
                                    selectedMedia: $selectedMedia,
                                    showGallery: $showGallery,
                                    mediasReports: $mediasReports,
                                    mediaComment: $mediaComment)
                        .onAppear {
                            // Проверяем, достиг ли пользователь конца списка и можем ли загрузить ещё данные
                            if index == viewModel.reports.count - 1 && viewModel.canLoadMore {
                                viewModel.loadMedias(for: tappedObjectId)
                            }
                        }
                }

                if viewModel.isLoadingPhoto {
                    ProgressView()
                        .padding()
                }
            }
            Spacer()
                .frame(height: 80)
        }
        .padding(.top, 14)
        .refreshable { 
            withAnimation(.easeInOut(duration: 0.5)) { // Плавное обновление при pull-to-refresh
                viewModel.resetPagination()
                viewModel.loadMedias(for: tappedObjectId)
            }
        }
    }

    private var AddReportButton: some View {
        VStack {
            Spacer()
            Button(action: {
                navigationPath.append(Destination.camerastruct)
            }) {
                Text("Добавить отчёт")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Colors.orange)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
            }
        }
    }
}

struct MediaReportView: View {
    var report: Report
    @Binding var selectedMediaIndex: Int
    @Binding var selectedMedia: Media?
    @Binding var showGallery: Bool
    @Binding var mediasReports: [Media]
    @Binding var mediaComment: String
    @State private var imageLoaded: [Int: Bool] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 4)) {
                MediaGrid(report: report,
                          selectedMediaIndex: $selectedMediaIndex,
                          selectedMedia: $selectedMedia,
                          showGallery: $showGallery,
                          mediasReports: $mediasReports,
                          mediaComment: $mediaComment,
                          imageLoaded: $imageLoaded)

            }
            .padding(.top, 16)
            .padding(.horizontal, 16)

            Text(report.comment ?? "")
                .font(Font.custom("Roboto", size: 14))
                .padding(.horizontal, 16)
                .foregroundColor(Color.black)

            HStack {
                Spacer()
                Text(formattedDate(from: report.created))
                    .font(Font.custom("Roboto", size: 14))
                    .foregroundColor(Colors.textFieldOverlayGray)
                    .padding(.horizontal, 16)
            }
        }
        .onTapGesture {
            let media = report.medias[0]
            selectedMediaIndex = 0
            selectedMedia = media
            showGallery = true
            mediasReports = report.medias // Передаем весь массив медиа
            mediaComment = report.comment ?? ""
        }
        .padding(.bottom, 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Colors.lightGrayOverlay, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, -8)
    }
}

struct MediaGrid: View {
    var report: Report
    @Binding var selectedMediaIndex: Int
    @Binding var selectedMedia: Media?
    @Binding var showGallery: Bool
    @Binding var mediasReports: [Media]
    @Binding var mediaComment: String
    @Binding var imageLoaded: [Int: Bool]
    
    var body: some View {
        
        let mediaCount = report.medias.count
        let maxVisibleItems = mediaCount <= 8 ? 8 : 7
        let hiddenCount = mediaCount > maxVisibleItems ? mediaCount - maxVisibleItems : 0
        
        // Показываем первые maxVisibleItems элементов
        ForEach(0..<min(mediaCount, maxVisibleItems), id: \.self) { index in
            let media = report.medias[index]
            MediaThumbnailView(media: media, index: index, imageLoaded: $imageLoaded)
                .onTapGesture {
                    selectedMediaIndex = index
                    selectedMedia = media
                    showGallery = true
                    mediasReports = report.medias // Передаем весь массив медиа
                    mediaComment = report.comment ?? ""
                }
        }
        
        // Если есть скрытые медиа, показываем миниатюру "+X"
        if hiddenCount > 0 {
            HiddenMediaView(hiddenCount: hiddenCount)
                .onTapGesture {
                    // Открываем галерею, показывая все медиа, начиная с 7-го
                    selectedMediaIndex = maxVisibleItems
                    selectedMedia = report.medias[maxVisibleItems]
                    showGallery = true
                    mediasReports = report.medias // Передаем весь массив медиа
                    mediaComment = report.comment ?? ""
                }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        ZStack {

            VStack {
                
                Image("visual-empty")
                    .resizable()
                    .frame(width: 140, height: 140)
                
                Text("Здесь будут отчёты")
                    .font(Fonts.Font_Headline1)
                
                Text("Мастера будут оставлять фото и видео")
                    .font(Fonts.Font_Callout)
                   
                Text("сделанных работ")
                    .font(Fonts.Font_Callout)
            }
        }
    }
}

struct MediaThumbnailView: View {
    var media: Media
    var index: Int
    @Binding var imageLoaded: [Int: Bool]
    @State private var imageLoadedВ: Bool = false
    
    var body: some View {
        ZStack {
            KFImage.url(URL(string: "\(media.thumbnailUrl ?? media.originalUrl)"))
                .requestModifier { request in
                    if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                    }
                }
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 260, height: 260)))
                                .loadDiskFileSynchronously(false)
                                .cacheOriginalImage()
                .placeholder {
                    ProgressView().frame(width: 76, height: 76)
                }
                .onSuccess { _ in
                    imageLoaded[index] = true
                    imageLoadedВ = true
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 76, height: 76)
                .cornerRadius(12)
            
            if imageLoadedВ == true && media.video {
                VideoPlayIconView()
            }
        }
    }
}

struct VideoPlayIconView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.black)
                .opacity(0.15)
                .frame(width: 32, height: 32)
                .cornerRadius(100)
            Image("play_arrow")

        }
    }
}

struct HiddenMediaView: View {
    var hiddenCount: Int
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Colors.lightGray2)
                .frame(width: 76, height: 76)
                .cornerRadius(12)
            Text("+\(hiddenCount)")
                .foregroundColor(Colors.orange)
                .font(Fonts.Font_Title3)
        }
    }
}

class ObjectPhotosViewModel: ObservableObject {
    @Published var reports: [Report] = []
    @Published var isLoadingPhoto: Bool = false
    @Published var currentPage: Int = 0
    @Published var canLoadMore: Bool = true
    @Published var isFirstLoadComplete: Bool = true
    @Published var shouldReloadData: Bool = true

    // Сбрасываем состояние пагинации и загружаем первую страницу
    func resetPagination() {
        print("Сбрасываем пагинацию...")
        reports = []
        currentPage = 0
        canLoadMore = true
        isFirstLoadComplete = true
        shouldReloadData = true
    }

    func loadMedias(for objectId: String) {
        // Проверяем, если данные уже были загружены и не нужно обновляться
        guard shouldReloadData || currentPage == 0 else {
            print("Данные уже загружены, пропускаем загрузку.")
            return
        }

        // Логирование начала запроса
        print("Запрос на загрузку страницы: \(currentPage), isLoading: \(isLoadingPhoto), canLoadMore: \(canLoadMore)")

        // Проверяем, идет ли загрузка или можно ли загружать данные
        guard !isLoadingPhoto, canLoadMore else {
            print("Пропускаем запрос, потому что либо уже загружается, либо больше нечего загружать.")
            return
        }

        isLoadingPhoto = true
        shouldReloadData = false
        
        let endpoint = "objects/reports"
        let queryParams = [
            URLQueryItem(name: "objectId", value: "\(objectId)"),
            URLQueryItem(name: "page", value: "\(currentPage)"),
            URLQueryItem(name: "limit", value: "10")
        ]

        guard var urlComponents = URLComponents(string: endpoint) else {
            isLoadingPhoto = false
            return
        }

        urlComponents.queryItems = queryParams

        guard let url = urlComponents.url else {
            isLoadingPhoto = false
            return
        }

        // Логирование запроса
        print("Отправляем запрос на URL: \(url.absoluteString)")

        NetworkAccessor.shared.get(url.absoluteString) { (result: Result<MainResponsePhoto, Error>, statusCode: Int?) in
            DispatchQueue.main.async {
                self.isLoadingPhoto = false
                switch result {
                case .success(let mainResponse):
                    if !mainResponse.content.isEmpty {
                        print("Получено данных: \(mainResponse.content.count) для страницы \(self.currentPage)")
                        self.reports.append(contentsOf: mainResponse.content)
                        self.currentPage += 1  // Увеличиваем текущую страницу для следующего запроса
                        self.isFirstLoadComplete = false
                        self.shouldReloadData = true  // Разрешаем дальнейшую подгрузку данных
                    } else {
                        print("Получен пустой массив данных. Дальнейшая загрузка невозможна.")
                        self.canLoadMore = false  // Если данных больше нет, запрещаем дальнейшую подгрузку
                        self.isFirstLoadComplete = false
                    }
                case .failure(let error):
                    print("Ошибка запроса: \(error)")
                }
            }
        }
    }
}

struct VideoPlayerView: View {
    @StateObject var videoPlayerManager: VideoPlayerManager
    @State private var videoProgress: Double = 0.00
    @State private var isVideoEnded: Bool = false  // Для отслеживания конца видео
    @State private var isControlsVisible: Bool = false  // Флаг для отображения элементов управления
    @Binding var mediaComment: String

    var body: some View {
        ZStack {
            if videoPlayerManager.isLoading {
                ProgressView("Загрузка видео...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if videoPlayerManager.player != nil {
                VideoPlayerUIView(player: videoPlayerManager.player!)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        addPlayerObservers()
                    }
                    .onDisappear {
                        videoPlayerManager.player?.pause()
                        removePlayerObservers()
                        if videoPlayerManager.isPlaying == true {
                            videoPlayerManager.isPlaying = false
                        }
                    }
                    .onTapGesture {
                        withAnimation {
                            isControlsVisible.toggle()
                        }
                    }
            }
            
            // Элементы управления с затемнённым фоном
            ZStack {
                VStack {
                    Spacer()
                    VStack {
                        // Прогресс бар
                        Text(mediaComment)
                            .font(Fonts.Font_Headline2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        
                        HStack {
                            Text("\(formattedTime(time: videoProgress * videoPlayerManager.videoDuration))")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .padding(.leading, 8)
                            
                            Slider(value: $videoProgress, in: 0...1, onEditingChanged: sliderEditingChanged)
                                .accentColor(.white)
                                .background(
                                    Color.clear.contentShape(Rectangle())  // Увеличиваем область клика по всей длине Slider
                                )
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let sliderWidth = UIScreen.main.bounds.width * 0.70
                                            let newValue = min(max(0, value.location.x / sliderWidth), 1)
                                            
                                            // Обновляем значение только при значительном изменении
                                            if abs(videoProgress - newValue) > 0.01 {
                                                videoProgress = newValue
                                            }
                                            videoPlayerManager.player?.pause()
                                        }
                                        .onEnded { _ in
                                            // Запрос перемотки после окончания перетягивания
                                            let newTime = videoProgress * videoPlayerManager.videoDuration
                                            videoPlayerManager.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
                                            
                                            // Продолжаем проигрывание только если оно было активным
                                            if videoPlayerManager.isPlaying {
                                                videoPlayerManager.player?.play()
                                            }
                                        }
                                )
                                .padding(16)

                            Text("\(formattedTime(time: videoPlayerManager.videoDuration))")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .padding(.trailing, 8)
                        }

                        .padding(.bottom, 68)
                    }
                    .background(Color.black.opacity(0.45))  // Затемнённый фон для нижней панели
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)  // Задаём высоту панели
                }
                
                // Кнопка Play/Pause
                Button(action: {
                    if isVideoEnded && videoProgress == 1 {
                        restartVideo()  // Перезапуск видео с начала
                    } else {
                        videoPlayerManager.togglePlayPause()
                    }
                }) {
                    Image(systemName: (videoPlayerManager.isPlaying && videoProgress != 1) ? "pause.fill" : "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 50))
                        .padding()
                }
            }
            .opacity(isControlsVisible ? 1 : 0)
            .animation(.easeInOut, value: isControlsVisible)
        }
    }

    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            videoPlayerManager.player?.pause()
        } else {
            let newTime = videoProgress * videoPlayerManager.videoDuration
            videoPlayerManager.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
            if videoPlayerManager.isPlaying {
                videoPlayerManager.player?.play()
            }
        }
    }

    private func formattedTime(time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func addPlayerObservers() {
        videoPlayerManager.player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: 600), queue: .main) { time in
            let progress = CMTimeGetSeconds(time) / videoPlayerManager.videoDuration
            self.videoProgress = progress
        }

        // Добавляем наблюдателя для конца видео
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: videoPlayerManager.player?.currentItem, queue: .main) { _ in
            self.isVideoEnded = true  // Устанавливаем флаг при завершении видео
        }
    }

    private func removePlayerObservers() {
        // Удаляем наблюдателей
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: videoPlayerManager.player?.currentItem)
    }

    private func restartVideo() {
        isVideoEnded = false  // Сбрасываем флаг конца видео
        videoProgress = 0.0
        videoPlayerManager.seek(to: .zero)  // Перемещаем воспроизведение в начало
        videoPlayerManager.player?.play()  // Запускаем воспроизведение
    }
}

class VideoPlayerManager: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying: Bool = false
    @Published var currentTime: CMTime = .zero
    @Published var videoDuration: Double = 0.00
    @Published var isLoading: Bool = true
    
    init(url: URL) {
        loadVideo(from: url)
    }
    
    // Функция загрузки видео с сервера
    private func loadVideo(from url: URL) {
        guard let accessToken = AccessTokenHolder.shared.getAccessToken() else {
            print("Access token not available")
            self.isLoading = false
            return
        }

        downloadVideo(from: url, accessToken: accessToken) { localURL in
            guard let localURL = localURL else {
                print("Failed to download video")
                self.isLoading = false
                return
            }

            let playerItem = AVPlayerItem(url: localURL)
            DispatchQueue.main.async {
                // Создаем новый плеер
                self.player = AVPlayer(playerItem: playerItem)
                self.videoDuration = playerItem.asset.duration.seconds
                self.isLoading = false
            }
        }
    }
    
    // Функция скачивания видео
    private func downloadVideo(from url: URL, accessToken: String, completion: @escaping (URL?) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.downloadTask(with: request) { temporaryURL, _, error in
            if let error = error {
                print("Error downloading video: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let temporaryURL = temporaryURL else {
                print("No data received")
                completion(nil)
                return
            }

            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory
            let localURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")

            do {
                try fileManager.moveItem(at: temporaryURL, to: localURL)
                completion(localURL)
            } catch {
                print("Failed to move video file: \(error.localizedDescription)")
                completion(nil)
            }
        }

        task.resume()
    }

    func togglePlayPause() {
        if player?.timeControlStatus == .playing {
            player?.pause()
            isPlaying = false
        } else {
            player?.play()
            isPlaying = true
        }
    }

    func seek(to time: CMTime) {
        player?.seek(to: time)
    }
}

struct VideoPlayerUIView: UIViewControllerRepresentable {
    var player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false // Отключаем встроенные контролы
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Обновляем состояние плеера
    }
}

// Модель для хранения состояния видео
struct VideoState {
    var currentTime: CMTime
    var isPlaying: Bool
}

struct MediaGalleryView: View {
    var medias: [Media]
    @Binding var selectedIndex: Int
    @Binding var mediasReports: [Media]
    @Binding var mediaComment: String
    @State private var videoStates: [String: VideoState] = [:]
    @Binding var showGallery: Bool
    
    @State private var isCommentVisible = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Основной контент галереи
                TabView(selection: $selectedIndex) {
                    ForEach(Array(mediasReports.enumerated()), id: \.offset) { index, media in
                        ZStack {
                            if media.video {
                                VideoPlayerView(videoPlayerManager: VideoPlayerManager(url: URL(string: media.originalUrl)!), mediaComment: $mediaComment)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            } else {
                                if let mediaUrl = URL(string: "\(media.originalUrl)") {
                                    ZoomableImage(
                                        url: mediaUrl,
                                        mediaComment: $mediaComment
                                    )
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    // Показать ошибку, если URL недействителен
                                    Text("Ошибка загрузки изображения")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .background(Color.black)
                
                // Верхняя панель с кнопкой и текстом
                VStack {
                    HStack {
                        Button(action: {
                            showGallery = false
                        }) {
                            HStack {
                                Image(systemName: "chevron.backward")
                                    .foregroundColor(.white)
                                Text("Медиа № \(selectedIndex + 1) из \(mediasReports.count)")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}


struct ZoomableImage: View {
    var url: URL?
    @Binding var mediaComment: String
    @State private var ismediaCommentVisible: Bool = false
    
    var body: some View {
        if let url = url {
            ZStack {
                
                Color.black  // Базовый слой фона
                            .edgesIgnoringSafeArea(.all)
                
                ZoomableScrollView {
                    KFImage.url(url)
                        .requestModifier { request in
                            if let accessToken = AccessTokenHolder.shared.getAccessToken() {
                                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                            }
                        }
                        .placeholder {
                            ProgressView().frame(width: 76, height: 76)
                        }
                        .onFailure { error in
                            print("Ошибка загрузки изображения: \(error)")
                        }
                        .resizable()
                        .background(Color.black)
                        .scaledToFit()
                        
                }
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    toggleControlsVisibilityComment() // Показываем/скрываем комментарий при тапе
                }
                .onDisappear {
                    ismediaCommentVisible = false
                }
                
                VStack {
                    Spacer()
                    if ismediaCommentVisible {
                        Text(mediaComment)
                            .font(Fonts.Font_Headline2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 52)
                            .padding(.top, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.45))
                            .transition(.move(edge: .bottom))
                            .animation(.easeInOut(duration: 0.6), value: ismediaCommentVisible)
                    }
                }
            }
        } else {
            Color.gray
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    private func toggleControlsVisibilityComment() {
        withAnimation {
            ismediaCommentVisible.toggle()
        }
    }
}

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 10
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .black  // Фон для scrollView

        let hostedView = context.coordinator.hostingController.view!
        hostedView.backgroundColor = .black  // Фон для hostedView
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)

        return scrollView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(hostingController: UIHostingController(rootView: self.content))
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = self.content
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>

        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
    }
}
