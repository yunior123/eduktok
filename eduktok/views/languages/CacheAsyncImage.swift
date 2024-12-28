//
//  CacheAsyncImage.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 26/3/24.
//

import SwiftUI
import Combine
import CryptoKit

class ImageCache {
    static let shared = ImageCache()
    private var memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // Configure cache limits
    private let maxMemoryLimit = 50 * 1024 * 1024  // 50 MB
    private let maxDiskLimit = 100 * 1024 * 1024   // 100 MB
    
    init() {
        memoryCache.totalCostLimit = maxMemoryLimit
        
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
        
        do {
            try fileManager.createDirectory(at: cacheDirectory,
                                          withIntermediateDirectories: true,
                                          attributes: nil)
        } catch {
            print("Failed to create cache directory: \(error)")
        }
        
        startCleanupTimer()
    }
    
    func image(for key: String) -> UIImage? {
        // First check memory cache
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // Then check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            guard let diskImage = UIImage(data: data) else { return nil }
            // Move to memory cache for faster access next time
            memoryCache.setObject(diskImage, forKey: key as NSString)
            return diskImage
        } catch {
            print("Failed to load image from disk: \(error)")
            return nil
        }
    }
    
    func insertImage(_ image: UIImage, for key: String) {
        // Save to memory cache
        memoryCache.setObject(image, forKey: key as NSString)
        
        // Save to disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        
        do {
            if let data = image.jpegData(compressionQuality: 0.8) {
                try data.write(to: fileURL)
            }
        } catch {
            print("Failed to write image to disk: \(error)")
        }
        
        cleanupDiskCacheIfNeeded()
    }
    
    private func cleanupDiskCacheIfNeeded() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let files = try self.fileManager.contentsOfDirectory(at: self.cacheDirectory,
                                                                   includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
                
                // Calculate total size
                let totalSize = files.reduce(0) { sum, url in
                    let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                    return sum + Int(fileSize)
                }
                
                if totalSize > self.maxDiskLimit {
                    let sortedFiles = files.sorted { file1, file2 in
                        let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                        let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                        return date1 < date2
                    }
                    
                    var currentSize = totalSize
                    for file in sortedFiles {
                        if currentSize <= self.maxDiskLimit {
                            break
                        }
                        let fileSize = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                        try? self.fileManager.removeItem(at: file)
                        currentSize -= Int(fileSize)
                    }
                }
            } catch {
                print("Error cleaning up disk cache: \(error)")
            }
        }
    }
    
    private func startCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.cleanupDiskCacheIfNeeded()
        }
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory,
                                       withIntermediateDirectories: true)
    }
}

extension String {
    var md5Hash: String {
        let digest = Insecure.MD5.hash(data: self.data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

// Error handling for image loading
enum ImageLoadingError: Error {
    case invalidURL
    case networkError(Error)
    case invalidData
}

struct CachedAsyncImage: View {
    let url: URL
    let placeholder: Image
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadingError: Error?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                placeholder
            }
        }
        .task {
            await loadImage()
        }
        .onChange(of: url) { _ in
            Task {
                await loadImage()
            }
        }
    }
    
    private func loadImage() async {
        guard !isLoading else { return }
        
        // Check cache first
        if let cachedImage = ImageCache.shared.image(for: url.absoluteString) {
            image = cachedImage
            return
        }
        
        isLoading = true
        loadingError = nil
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let loadedImage = UIImage(data: data) else {
                throw ImageLoadingError.invalidData
            }
            
            ImageCache.shared.insertImage(loadedImage, for: url.absoluteString)
            
            await MainActor.run {
                image = loadedImage
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadingError = error
                isLoading = false
            }
            print("Failed to load image: \(error)")
        }
    }
}
