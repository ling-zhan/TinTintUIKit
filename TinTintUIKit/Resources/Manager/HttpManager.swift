//
//  HttpManager.swift
//  TinTintUIKit
//
//  Created by Ling Zhan on 2024/12/16.
//

import UIKit
import Combine

enum HttpError: Error {
    case invalidUrl
    case invalidData
    case invalidResponse
    case unknown
}

class HttpManager {
    
    static var shared = HttpManager()
    
    let baseUrl: String = "https://jsonplaceholder.typicode.com"
    
    func fetchAlbums() -> AnyPublisher<[Album], HttpError>  {
        
        let endpoint: String = "/photos"
        let urlString = baseUrl + endpoint
        
        guard let url = URL(string: urlString) else {
            return Fail(error: HttpError.invalidUrl).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response in
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HttpError.invalidResponse
                }
                
                guard httpResponse.statusCode == 200 else {
                    throw HttpError.invalidResponse
                }
                return data
            }
            .decode(type: [Album].self, decoder: JSONDecoder())
            .map { $0 }
            .mapError { _ in HttpError.invalidData }
            .eraseToAnyPublisher()
    }
    
    func fetchImage(from urlString: String, id: Int) -> AnyPublisher<UIImage, HttpError> {
        guard let url = URL(string: urlString) else {
            return Fail(error: HttpError.invalidUrl).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response in
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HttpError.invalidResponse
                }
                
                guard httpResponse.statusCode == 200 else {
                    throw HttpError.invalidResponse
                }
                
                // 將資料轉換為 UIImage
                guard let image = UIImage(data: data) else {
                    throw HttpError.invalidData
                }
                
                // 儲存圖片到 Disk Cache 並檢查是否需要清理(避免影響效能使用 背景執行)
                DispatchQueue.global(qos: .background).async {
                    ImageCacheManager.shared.saveImageToDisk(image, id: id, forKey: urlString)
                }
                
                return image
            }
            .mapError { error in
                // 將 Combine 的錯誤轉換為 HttpError
                if let httpError = error as? HttpError {
                    return httpError
                } else {
                    return .unknown
                }
            }
            .eraseToAnyPublisher()
    }
}
