// The Swift Programming Language
// https://docs.swift.org/swift-book
//
//  NetworkManager.swift
//  GeliStore
//
//  Created by telkanishvili on 06.07.24.
//
import Foundation

public enum NetworkError: Error {
    case invalidResponse
    case httpError(code: Int)
    case noData
    case decodeError
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

public struct EmptyResponse: Decodable {
    // it represents an empty response
}

public class NetworkService {

    public init() { }

    public func requestData<T: Decodable>(
        urlString: String,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidResponse))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        if let body = body {
            request.httpBody = body
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.httpError(code: httpResponse.statusCode)))
                return
            }

            if method == .post {
                if T.self == EmptyResponse.self {
                    completion(.success(EmptyResponse() as! T))
                } else {
                    guard let data = data else {
                        completion(.failure(NetworkError.noData))
                        return
                    }

                    do {
                        let decoder = JSONDecoder()
                        let object = try decoder.decode(T.self, from: data)
                        completion(.success(object))
                    } catch {
                        completion(.failure(NetworkError.decodeError))
                    }
                }
            } else {
                guard let data = data else {
                    completion(.failure(NetworkError.noData))
                    return
                }

                do {
                    let decoder = JSONDecoder()
                    let object = try decoder.decode(T.self, from: data)
                    completion(.success(object))
                } catch {
                    completion(.failure(NetworkError.decodeError))
                }
            }
        }.resume()
    }
}
