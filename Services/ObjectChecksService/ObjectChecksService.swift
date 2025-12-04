import Foundation

final class ObjectChecksService {
    func getTickets(objectId: String, page: String, nomenclatureId: String?) async throws -> GetTicketsResponse {
        let endpoint = ObjectChecksTarget.getTickets.requestPath
        var queryParams = [
            URLQueryItem(name: "objectId", value: objectId),
            URLQueryItem(name: "page", value: page),
            URLQueryItem(name: "limit", value: "10"),
           
        ]
        if let nomenclatureId {
            queryParams.append( URLQueryItem(name: "nomenclatureId", value: nomenclatureId))
        }

        guard var urlComponents = URLComponents(string: endpoint) else {
            throw ApiError.invalidUrl
        }

        urlComponents.queryItems = queryParams

        guard let url = urlComponents.url else {
            throw ApiError.invalidUrl
        }

        return try await withCheckedThrowingContinuation { continuation in
            NetworkAccessor.shared.get(url.absoluteString) { (result: Result<GetTicketsResponse, Error>, statusCode: Int?) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response) // Возвращаем успешный результат
                    case .failure(let error):
                        continuation.resume(throwing: error) // Пробрасываем ошибку
                    }
                }
            }
        }
    }
}
