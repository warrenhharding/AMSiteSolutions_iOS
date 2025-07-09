//
//  UIImageExtension.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/03/2025.
//

import UIKit

extension UIImage {
    func resizedImageWithinRect(rectSize: CGSize) -> UIImage {
        let widthRatio = rectSize.width / self.size.width
        let heightRatio = rectSize.height / self.size.height
        let scale = min(widthRatio, heightRatio)
        let newSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

// Basic helper function to load an image from a URL
func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
    print("Loading image from URL: \(url.absoluteString)")
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("Error loading image: \(error.localizedDescription)")
            completion(nil)
        } else if let data = data, let image = UIImage(data: data) {
            completion(image)
        } else {
            completion(nil)
        }
    }.resume()
}

