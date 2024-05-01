// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation

public enum NetworkError: Error {
    case decodeError
    case wrongResponse
    case wrongStatusCode(code: Int)
}
//MARK: - Network Get Request

public class NetworkService {
    public func getData<T: Decodable>(urlString: String, completion: @escaping (T?,Error?) ->(Void)) {
        var tryCount = 0
        let url = URL(string: urlString)!
        if tryCount <= 3 {
            URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
                
                if let error {
                    print(error.localizedDescription)
                }
                
                guard let response = response as? HTTPURLResponse else {
                    return
                }
                
                guard (200...299).contains(response.statusCode) else {
                    print("wrong response")
                    return
                }
                
                guard let data else { return }

                do {
                    let decoder = JSONDecoder()
                    let object = try decoder.decode(T.self, from: data)
                                    
                    DispatchQueue.main.async {
                        completion(object, nil)
                    }
                } catch {
                    print("Error decoding data:", error)
                    completion(nil, NetworkError.decodeError)
                    tryCount += 1
                }
            }.resume()
        }
        
    }
}
