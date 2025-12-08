//
//  DrugAndDropDocument.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 18.09.2024.
//

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

// Генерация имени файла PDF в формате DOC_19.09.2024.pdf


struct DrugAndDropDocument: View {
    
    @Binding var navigationPath: NavigationPath
    @Binding var capturedMediaDoc: [CapturedMediaDocument]
    
    @State private var dragItem: CapturedMediaDocument?
    @Binding var tappedObjectId: String
    @State private var loadingStates: [CapturedMediaDocument: Bool] = [:] // Храним состояние загрузки каждого медиа
    
    @Binding var generatedPDFURL: URL? // Для хранения URL сгенерированного PDF


    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 8) {
                    ForEach(capturedMediaDoc, id: \.self) { item in
                        ZStack {
                            switch item {
                            case .image(let image):
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 84, height: 150)
                                    .cornerRadius(12)
                                    .shadow(radius: 5)
                            }
                            
                            if loadingStates[item] == true {
                                Color.black.opacity(0.8)
                                    .cornerRadius(12)
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(2.0)
                                    )
                            }
                            
                            Button(action: {
                                removeItem(item)
                            }) {
                                Image("cancel")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.orange)
                                    .padding(.top, 4)
                                    .padding(.trailing, 8)
                                
                            }
                            .padding(.top, -72)
                            .padding(.leading, 64)
                        }
                        .onDrag {
                            self.dragItem = item
                            return NSItemProvider(object: "\(item)" as NSString)
                        }
                        .onDrop(of: [UTType.text], delegate: DropViewDelegateDoc(item: item, items: $capturedMediaDoc, dragItem: $dragItem))
                    }
                }
                .padding()
                .animation(.easeInOut, value: capturedMediaDoc)
            }
            Spacer()
            
            Button(
                action: {
                    if let pdfURL = createPDF(from: capturedMediaDoc) {
                        generatedPDFURL = pdfURL // Сохраняем сгенерированный PDF
                        navigationPath.append(Destination.createdocumentview) // Переход к CreateDocumentView
                    }
                    
                },
                label: {
                    Text("Продолжить")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.orange)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                })
        }
        .navigationBarTitle("Формирование документа")
    }
    
    // Удаление медиа из массива с анимацией
    private func removeItem(_ item: CapturedMediaDocument) {
        if let index = capturedMediaDoc.firstIndex(of: item) {
            withAnimation {
                capturedMediaDoc.remove(at: index)
                if capturedMediaDoc.isEmpty {
                    navigationPath.removeLast(1)
                }
            }
        }
    }
    
    // Сохранение изображения во временную директорию
    private func saveImageToTempDirectory(image: UIImage) -> String? {
        let filename = UUID().uuidString + ".jpg"
        let tempDirectory = NSTemporaryDirectory()
        let fileURL = URL(fileURLWithPath: tempDirectory).appendingPathComponent(filename)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: fileURL)
                return fileURL.path
            } catch {
                print("Ошибка сохранения изображения: \(error)")
                return nil
            }
        }
        return nil
    }
    
    func generatePDFFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy" // Формат даты "19.09.2024"
        let currentDate = dateFormatter.string(from: Date()) // Получаем текущую дату
        
        return "DOC_\(currentDate).pdf" // Создаем имя файла  \(tappedObjectId)
    }

    // Функция для создания PDF
    func createPDF(from mediaDocuments: [CapturedMediaDocument]) -> URL? {
        // Генерируем имя файла PDF
        let pdfFileName = generatePDFFileName()
        
        // Путь для сохранения временного файла PDF
        let pdfFilePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(pdfFileName)
        
        // Создаём PDF-документ
        let pdfDocument = PDFDocument()

        for (index, media) in mediaDocuments.enumerated() {
            switch media {
            case .image(let image):
                // Создание страницы PDF для каждого изображения
                if let pdfPage = PDFPage(image: image) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
        }

        // Сохраняем PDF в файл
        if pdfDocument.write(to: pdfFilePath) {
            return pdfFilePath
        } else {
            print("Не удалось сохранить PDF")
            return nil
        }
    }
}


struct DropViewDelegateDoc: DropDelegate {
    let item: CapturedMediaDocument
    @Binding var items: [CapturedMediaDocument]
    @Binding var dragItem: CapturedMediaDocument?

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



//#Preview {
//    DrugAndDropDocument()
//}
