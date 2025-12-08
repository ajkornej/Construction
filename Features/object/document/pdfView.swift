//
//  pdfView.swift
//  stroymir
//
//  Created by Корнеев Александр on 28.06.2024.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import UIKit
// смотреть на content type
// посмотреть дисплей тайтл для присаивания имени файла при скачивании

struct pdfView: View {
    @Binding var navigationPath: NavigationPath
    @Binding var selectedFile: String
    @Binding var selectedFileName: String
    @State private var pdfDocument: PDFDocument?
    @State private var isPDFFile: Bool = true // Для отслеживания типа файла
    @State private var isLoadingFile = false
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        VStack {
            ZStack {
                if isPDFFile {
                    if let pdfDocument = pdfDocument {
                        PDFKitRepresentedView(document: pdfDocument)
                            .ignoresSafeArea()
                            .foregroundColor(.white)
                    } else {
                        HStack {
                            Text("Загрузка PDF")
                            ProgressView()
                                .padding(.horizontal, 8)
                        }
                    }
                } else {
                    VStack {
                        Text("Просмотр недоступен")
                            .font(Font.custom("Roboto", size: 20).weight(.bold))
                            
                        Text("Данный тип документа не поддерживается")
                            .font(Fonts.Font_Callout)
                            .padding(.top, 8)
                        Text("для просмотра")
                            .font(Fonts.Font_Callout)
                        Button(action: saveFileToDownloads) {
                            if isLoadingFile {
                                ProgressView()
                            } else {
                                Text("Скачать")
                                    .foregroundColor(Colors.orange)
                            }
                        }
                        .padding(.top, 12)
                    }
                }
                if showToast {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.bottom, 50)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .zIndex(1)
                    }
                    .animation(.easeInOut(duration: 0.3), value: showToast)
                }
            }
        }
        .onAppear(perform: downloadFile)
        .toolbar {
            if isPDFFile {
                Button(action: savePDFFileWithPicker) {
                    if isLoadingFile {
                        ProgressView()
                    } else {
                        Image("downloadPdf")
                    }
                }
            }
        }
        .navigationTitle(selectedFileName)
    }

    private func downloadFile() {
        isLoadingFile = true
        let endpoint = selectedFile
        let fileExtension = URL(string: endpoint)?.pathExtension.lowercased() ?? ""

        NetworkAccessor.shared.get(endpoint) { (result: Result<Data?, Error>, statusCode: Int?) in
            DispatchQueue.main.async {
                self.isLoadingFile = false
                switch result {
                case .success(let data):
                    guard let fileData = data, fileData.count > 0 else {
                        self.showToastMessage("Ошибка загрузки: файл пустой или отсутствует")
                        self.isPDFFile = false
                        return
                    }
                    
                    if fileExtension == "pdf", let document = PDFDocument(data: fileData) {
                        self.pdfDocument = document
                        self.isPDFFile = true
                    } else {
                        self.isPDFFile = false
                    }

                case .failure(let error):
                    self.showToastMessage("Ошибка загрузки: \(error.localizedDescription) \(String(describing: statusCode)), \(fileExtension)")
                    print("Ошибка загрузки: \(error.localizedDescription) \(String(describing: statusCode)), \(fileExtension)")
                }
            }
        }
    }

    private func savePDFFileWithPicker() {
        guard let data = pdfDocument?.dataRepresentation() else {
            print("Ошибка: данные PDF отсутствуют")
            return
        }
        let fileName = selectedFileName.hasSuffix(".pdf") ? selectedFileName : "\(selectedFileName).pdf"
        saveFileWithDocumentPicker(fileData: data, fileName: fileName)
    }

    private func saveFileToDownloads() {
        isLoadingFile = true
        NetworkAccessor.shared.get(selectedFile) { (result: Result<Data?, Error>, statusCode: Int?) in
            DispatchQueue.main.async {
                self.isLoadingFile = false
                switch result {
                case .success(let data):
                    guard let fileData = data, fileData.count > 0 else {
                        self.showToastMessage("Ошибка загрузки: файл пустой или отсутствует")
                        return
                    }
                    let fileExtension = URL(string: selectedFile)?.pathExtension.lowercased() ?? "tmp"
                    let fileName = selectedFileName.hasSuffix(".\(fileExtension)") ? selectedFileName : "\(selectedFileName).\(fileExtension)"
                    self.saveFileWithDocumentPicker(fileData: fileData, fileName: fileName)

                case .failure(let error):
                    self.showToastMessage("Ошибка загрузки: \(error.localizedDescription)")
                }
            }
        }
    }

    private func saveFileWithDocumentPicker(fileData: Data, fileName: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try fileData.write(to: tempURL)
            DispatchQueue.main.async {
                let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: true)
                documentPicker.delegate = makeCoordinator()
                documentPicker.modalPresentationStyle = .formSheet
                UIApplication.shared.windows.first?.rootViewController?.present(documentPicker, animated: true)
            }
            showToastMessage("Файл успешно загружен") // Тост при успешной загрузке PDF
        } catch {
            print("Ошибка при сохранении временного файла: \(error)")
            showToastMessage("Ошибка при сохранении файла")
        }
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showToast = false
            }
        }
    }
}

// MARK: - Coordinator для обработки завершения Document Picker
extension pdfView {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: pdfView
        
        init(_ parent: pdfView) { self.parent = parent }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if !urls.isEmpty {
                parent.showToastMessage("Файл успешно загружен")
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.showToastMessage("Сохранение отменено")
        }
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    var document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}
