// The Swift Programming Language
// https://docs.swift.org/swift-book
//
//  NetworkManager.swift
//  GeliStore
//
//  Created by telkanishvili on 06.07.24.
//
import Foundation

// Enum for Network Errors
public enum NetworkError: Error {
    case invalidResponse
    case httpError(code: Int)
    case noData
    case decodeError
}

// Enum for HTTP Methods
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

// NetworkService class for making requests
public class NetworkService {

    public init() { }
    
    // Function to perform a generic HTTP request
    public func requestData<T: Decodable>(
        urlString: String,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
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
                print("Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let invalidResponseError = NetworkError.invalidResponse
                print("Invalid response")
                completion(.failure(invalidResponseError))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let httpError = NetworkError.httpError(code: httpResponse.statusCode)
                print("HTTP error: \(httpResponse.statusCode)")
                completion(.failure(httpError))
                return
            }
            
            // Handle POST request without expecting data in the response
            if method == .post {
                // Check if T is Void, in which case we return success with Void
                if T.self == Void.self {
                    DispatchQueue.main.async {
                        completion(.success(() as! T)) // Cast to T, which is Void
                    }
                } else {
                    // For other types, attempt to decode the response data
                    guard let data = data else {
                        let noDataError = NetworkError.noData
                        print("No data")
                        completion(.failure(noDataError))
                        return
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        let object = try decoder.decode(T.self, from: data)
                        DispatchQueue.main.async {
                            completion(.success(object))
                        }
                    } catch {
                        print("Error decoding data:", error)
                        completion(.failure(NetworkError.decodeError))
                    }
                }
            } else {
                // Handle other HTTP methods or scenarios where data is expected
                guard let data = data else {
                    let noDataError = NetworkError.noData
                    print("No data")
                    completion(.failure(noDataError))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let object = try decoder.decode(T.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(object))
                    }
                } catch {
                    print("Error decoding data:", error)
                    completion(.failure(NetworkError.decodeError))
                }
            }
        }.resume()
    }
}
