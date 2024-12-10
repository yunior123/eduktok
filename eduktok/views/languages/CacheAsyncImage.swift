//
//  CacheAsyncImage.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 26/3/24.
//

import SwiftUI
import Combine

// ImageCache class to manage image caching
class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, UIImage>()

    func image(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func insertImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}

// AsyncImage view with cache management
struct CachedAsyncImage: View {
    let url: URL
    let placeholder: Image
    @State private var image: UIImage?

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            placeholder
                .onAppear {
                    loadImage()
                }
        }
    }

    private func loadImage() {
        if let cachedImage = ImageCache.shared.image(for: url.absoluteString) {
            image = cachedImage
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil, let loadedImage = UIImage(data: data) else { return }
            ImageCache.shared.insertImage(loadedImage, for: url.absoluteString)
            DispatchQueue.main.async {
                image = loadedImage
            }
        }.resume()
    }
}
