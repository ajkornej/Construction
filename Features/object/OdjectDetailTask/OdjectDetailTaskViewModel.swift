//
//  ObjectDetailTaskViewModel.swift
//  stroymir-ios
//
//  Created by Корнеев Александр on 13.05.2025.
//

import Foundation
import SwiftUI

class ObjectDetailTaskViewModel: ObservableObject {

    @Published var tasksObjectDetails: [TaskModel] = []
    @Published var isLoading: Bool = false

    func loadTask(for objectId: String, page: Int = 0) {
        isLoading = true

        // 1. Parse base URL
        print("🔧 Step 1: Parsing baseURL: \(AppConfig.baseURL)")
        guard let baseComponents = URLComponents(string: AppConfig.baseURL) else {
            print("❌ ERROR: Invalid baseURL components")
            isLoading = false
            return
        }

        // 2. Build final URL
        print("🔧 Step 2: Building final URL components")
        var urlComponents = URLComponents()
        urlComponents.scheme = baseComponents.scheme
        urlComponents.host = baseComponents.host
        urlComponents.path = baseComponents.path + "objects/tasks"
        urlComponents.queryItems = [
            URLQueryItem(name: "objectId", value: objectId),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "100")
        ]

        guard let url = urlComponents.url else {
            print("❌ ERROR: Invalid final URL components")
            isLoading = false
            return
        }

        print("✅ Final URL: \(url.absoluteString)")

        // 3. Network call
        NetworkAccessor.shared.get(url.absoluteString) { [weak self] (result: Result<TaskResponse, Error>, statusCode: Int?) in
            DispatchQueue.main.async {
                self?.isLoading = false
                print("📡 Response code: \(statusCode ?? -1)")

                switch result {
                case .success(let taskResponse):
                    print("✔️ Received \(taskResponse.content.count) tasks")
                    self?.tasksObjectDetails = taskResponse.content

                case .failure(let error):
                    print("❌ NETWORK ERROR: \(error.localizedDescription)")
                }
            }
        }
    }
}


struct TaskResponse: Decodable {
    let content: [TaskModel]
}

struct Task2: Codable, Identifiable {
    let id: String
    let title: String
    let creator: Userr
    let deadline: TimeInterval
    let description: String
    let progress: String
    let objectIds: [String]
    let executors: [ExecutorWrapper]
    let isProblem: Bool
    let medias: [Media]
    let buttonText: String?
    let canEdit: Bool
    let canDelete: Bool

    enum CodingKeys: String, CodingKey {
        case id = "taskId"
        case title, creator, deadline, description, progress, objectIds, executors, isProblem, medias, buttonText, canEdit, canDelete
    }
}

struct Userr: Codable {
    let userId: String
    let name: String
    let surname: String
    let isEmployee: Bool
    let patronymic: String
    let imageUrl: String?
    let jobTitle: String
}

struct ExecutorWrapper: Codable {
    let executor: User
    let status: String
    let statusColor: ColorHex
    let date: TimeInterval
    let canBeAccepted: Bool
}
struct ColorHex: Codable {
    let hex: String

    var color: Color {
        Color(hex: hex)
    }
}

