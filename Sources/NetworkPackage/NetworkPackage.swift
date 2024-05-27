// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation

public enum NetworkError: Error {
    case invalidResponse
    case httpError(code: Int)
    case noData
    case decodeError
    
}
//MARK: - Network Get Request

public class NetworkService {
    
    public init() { }
    
    public func getData<T: Decodable>(urlString: String, headers: [String: String]? = nil, completion: @escaping (T?, Error?) -> Void) {

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(nil, NetworkError.invalidResponse)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let invalidResponseError = NetworkError.invalidResponse
                print("Invalid response")
                completion(nil, invalidResponseError)
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let httpError = NetworkError.httpError(code: httpResponse.statusCode)
                print("HTTP error: \(httpResponse.statusCode)")
                completion(nil, httpError)
                return
            }
            
            guard let data = data else {
                let noDataError = NetworkError.noData
                print("No data")
                completion(nil, noDataError)
                return
            }

            do {
                let decoder = JSONDecoder()
                let object = try decoder.decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(object, nil)
                }
            } catch {
                print("Error decoding data:", error)
                completion(nil, NetworkError.decodeError)
            }
        }.resume()
    }
}
