import Foundation

class NetworkAccessor {

    static let shared = NetworkAccessor()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    
    // Базовый URL
    let baseURL = URL(string: AppConfig.baseURL)!
    

    func get(_ endpoint: String, completion: @escaping (Result<Data?, Error>, Int?) -> Void) {
        performRequest(endpoint, method: "GET", completion: completion)
    }

    func get<T: Decodable>(_ endpoint: String, completion: @escaping (Result<T, Error>, Int?) -> Void) {
        performTypedRequest(endpoint, method: "GET", completion: completion)
    }

    func post<B: Encodable>(_ endpoint: String, body: B?, completion: @escaping (Result<Data?, Error>, Int?) -> Void) {
        do {
            let encodedBody = try JSONEncoder().encode(body)
            performRequest(endpoint, method: "POST", body: encodedBody, completion: completion)
        } catch let error {
            completion(.failure(error), nil)
        }
    }

    func post<T: Decodable, B: Encodable>(_ endpoint: String, body: B?, completion: @escaping (Result<T, Error>, Int?) -> Void) {
        performBothTypedRequest(endpoint, method: "POST", body: body, completion: completion)
    }

    func put<B: Encodable>(_ endpoint: String, body: B?, completion: @escaping (Result<Data?, Error>, Int?) -> Void) {
        do {
            let encodedBody = try JSONEncoder().encode(body)
            performRequest(endpoint, method: "PUT", body: encodedBody, completion: completion)
        } catch let error {
            completion(.failure(error), nil)
        }
    }

    func put<T: Decodable, B: Encodable>(_ endpoint: String, body: B?, completion: @escaping (Result<T, Error>, Int?) -> Void) {
        performBothTypedRequest(endpoint, method: "PUT", body: body, completion: completion)
    }

    func delete<T: Decodable>(_ endpoint: String, completion: @escaping (Result<T, Error>, Int?) -> Void) {
        performTypedRequest(endpoint, method: "DELETE", completion: completion)
    }

    // Обработка запроса с телом и статусом
    private func performBothTypedRequest<T: Decodable, B: Encodable>(
        _ endpoint: String,
        method: String,
        body: B? = nil,
        completion: @escaping (Result<T, Error>, Int?) -> Void
    ) {
        guard let unwrappedBody = body else {
            performTypedRequest(endpoint, method: method, completion: completion)
            return
        }

        do {
            let encodedBody = try JSONEncoder().encode(unwrappedBody)
            performTypedRequest(endpoint, method: method, body: encodedBody, completion: completion)
        } catch let error {
            completion(.failure(error), nil)
        }
    }

    // Выполнение запроса с декодированием
    private func performTypedRequest<T: Decodable>(
        _ endpoint: String,
        method: String,
        body: Data? = nil,
        completion: @escaping (Result<T, Error>, Int?) -> Void
    ) {
        performRequest(endpoint, method: method, body: body) { (result: Result<Data?, Error>, statusCode: Int?) in
            switch result {
            case .success(let data):
                do {
                    let decodedResponse = try JSONDecoder().decode(T.self, from: data!)
                    completion(.success(decodedResponse), statusCode)
                } catch let error {
                    completion(.failure(error), statusCode)
                }
            case .failure(let error):
                completion(.failure(error), statusCode)
            }
        }
    }

    // Основной метод для выполнения сетевого запроса
    private func performRequest(
        _ endpoint: String,
        method: String,
        body: Data? = nil,
        completion: @escaping (Result<Data?, Error>, Int?) -> Void
    ) {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])), nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Добавляем заголовок с токеном доступа
        if let token = AccessTokenHolder.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error), nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode

                guard let data = data else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Data"])), statusCode)
                    return
                }

                completion(.success(data), statusCode)
            } else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Response"])), nil)
            }
        }

        task.resume()
    }
}

