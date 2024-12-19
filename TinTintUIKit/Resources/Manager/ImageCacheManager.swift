//
//  ImageCacheManager.swift
//  TinTintUIKit
//
//  Created by Ling Zhan on 2024/12/16.
//
//  將圖片加入 memory cache 及 disk 中，並做大小與保留天數的檢查避免爆量
//  1. 在每次保存圖片到磁碟時進行 清理檢查
//  2. 在每次下載完成後執行 清理檢查

import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheExpiryDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 天
    private let maxDiskCacheSize: Int = 3 * 1024 * 1024 // 3 MB
    
    // MARK: - Memory Cache
    func getImage(forKey key: String) -> UIImage? {
        return memoryCache.object(forKey: key as NSString)
    }
    
    func saveImage(_ image: UIImage, id: Int, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
    }
    
    // MARK: - Disk Cache
    func getImageFromDisk(forKey key: String) -> UIImage? {
        guard let filePath = filePath(forKey: key),
              fileManager.fileExists(atPath: filePath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    func saveImageToDisk(_ image: UIImage, id: Int, forKey key: String) {
        // 檔案名稱依照 https://via.placeholder.com/150/ 網址做儲存
        guard let filePath = filePath(forKey: key),
              let data = image.pngData() else {
            return
        }
        
        let fileDirectory = (filePath as NSString).deletingLastPathComponent
        if !fileManager.fileExists(atPath: fileDirectory) {
            do {
                try fileManager.createDirectory(atPath: fileDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return
            }
        }
        
        do {
            try data.write(to: URL(fileURLWithPath: filePath))
            enforceDiskCacheSizeLimit()
        } catch {
        }
    }
    
    // MARK: - 檢查與清理快取
    func cleanUpDiskCache() {
        /* 根據圖片的存放時間自動刪除過期圖片 */
        
        guard let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let fileURLs = try? fileManager.contentsOfDirectory(at: cachesDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
        
        fileURLs?.forEach { fileURL in
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let modificationDate = attributes[.modificationDate] as? Date {
                let timeIntervalSinceModified = Date().timeIntervalSince(modificationDate)
                if timeIntervalSinceModified > cacheExpiryDuration {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        }
    }
    
    //MARK: - 檢查 DiskCach 上限，並刪除檔案
    func enforceDiskCacheSizeLimit() {
        /* 保持 Disk 總大小低於設定的上限，超過最舊的檔案 */
        
        guard let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        
        let fileURLs = (try? fileManager.contentsOfDirectory(
            at: cachesDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        )) ?? []
        
        var totalSize: Int = 0
        var filesWithSizes: [(url: URL, size: Int, date: Date)] = []
        
        // 計算當前磁碟 Cache 大小並記錄文件
        for fileURL in fileURLs {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? Int,
               let modificationDate = attributes[.modificationDate] as? Date {
                totalSize += fileSize
                filesWithSizes.append((url: fileURL, size: fileSize, date: modificationDate))
            }
        }
        
        // 超過上限時，按日期排序並清理最舊的檔案
        if totalSize > maxDiskCacheSize {
            // 依修改日期升序排序（舊的優先）
            filesWithSizes.sort { $0.date < $1.date }
            
            for file in filesWithSizes {
                // 刪除檔案
                try? fileManager.removeItem(at: file.url)
                totalSize -= file.size
                if totalSize <= maxDiskCacheSize { break }
            }
        }
    }
    
    private func filePath(forKey key: String) -> String? {
        guard let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        // 使用 addingPercentEncoding 確保檔案名稱不包含非法字元
        let fileName = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        return cachesDirectory.appendingPathComponent(fileName).path
    }
}
