import SwiftUI
import Network

class NetworkMonitor: ObservableObject {
    private var monitor: NWPathMonitor
    private let queue = DispatchQueue.global(qos: .background)
    
    @Published var isConnected: Bool = true
    
    init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

struct NetworkBanner: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        // Всплывающее уведомление при отсутствии интернета
        if !networkMonitor.isConnected {
            VStack {
                Spacer()
                Text("Нет подключения к интернету!")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
                    .shadow(radius: 10)
                    .transition(.move(edge: .top))
            }
            .padding(.top, 20)
            .animation(.easeInOut, value: networkMonitor.isConnected)
        }
    }
}

