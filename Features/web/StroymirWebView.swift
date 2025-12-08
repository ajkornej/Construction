import SwiftUI
import WebKit

struct StroymirWebView: View {
    
    let url: String
    
    let title: String
    
    @State
    private var progress: Float = 0.0
    
    var body: some View {
        ZStack {
            if let url = URL(string: url) {
                WebView(url: url, progress: $progress)
                    .edgesIgnoringSafeArea(.all)
                    .padding(.top, 12)
                    .navigationTitle(title)
                
                VStack{
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(Colors.orange)
                        .opacity(progress < 1.0 ? 1.0 : 0.0)
                        .padding(.top, 0)
                        .padding(.horizontal, 16)
                    
                    Spacer()
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    
    let url: URL
    
    @Binding var progress: Float
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard keyPath == "estimatedProgress" else { return }
            if let progress = (object as? WKWebView)?.estimatedProgress {
                self.parent.progress = Float(progress)
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.progress = 1.0
        }
    }
}

struct WebViewDestination : Hashable {
    let url: String
    let title: String
}
