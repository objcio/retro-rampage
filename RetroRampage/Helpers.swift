//
//  Helpers.swift
//  RetroRampage
//
//  Created by Chris Eidhof on 05.12.19.
//  Copyright © 2019 Chris Eidhof. All rights reserved.
//

import UIKit

extension ViewController {
    func setUpImageView() {
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.magnificationFilter = .nearest
    }
}

extension Color {
    static let clear = Color(r: 0, g: 0, b: 0, a: 0)
    static let black = Color(r: 0, g: 0, b: 0)
    static let white = Color(r: 255, g: 255, b: 255)
    static let gray = Color(r: 192, g: 192, b: 192)
    static let red = Color(r: 255, g: 0, b: 0)
    static let green = Color(r: 0, g: 255, b: 0)
    static let blue = Color(r: 0, g: 0, b: 255)
}

extension UIImage {
    convenience init?(bitmap: Bitmap) {
        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let bytesPerPixel = MemoryLayout<Color>.stride
        let bytesPerRow = bitmap.width * bytesPerPixel

        guard let providerRef = CGDataProvider(data: Data(bytes: bitmap.pixels, count: bitmap.height * bytesPerRow) as CFData) else {
            return nil
        }

        guard let cgImage = CGImage(
            width: bitmap.width,
            height: bitmap.height,
            bitsPerComponent: 8,
            bitsPerPixel: bytesPerPixel * 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: alphaInfo.rawValue),
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            return nil
        }

        self.init(cgImage: cgImage)

    }
}

extension Vector {
    static func +(lhs: Vector, rhs: Vector) -> Vector {
        return Vector(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func - (lhs: Vector, rhs: Vector) -> Vector {
         return Vector(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
     }
     
     static func * (lhs: Vector, rhs: Double) -> Vector {
         return Vector(x: lhs.x * rhs, y: lhs.y * rhs)
     }
     
     static func / (lhs: Vector, rhs: Double) -> Vector {
         return Vector(x: lhs.x / rhs, y: lhs.y / rhs)
     }

     static func * (lhs: Double, rhs: Vector) -> Vector {
         return Vector(x: lhs * rhs.x, y: lhs * rhs.y)
     }

     static func / (lhs: Double, rhs: Vector) -> Vector {
         return Vector(x: lhs / rhs.x, y: lhs / rhs.y)
     }
     
     static func += (lhs: inout Vector, rhs: Vector) {
         lhs.x += rhs.x
         lhs.y += rhs.y
     }

     static func -= (lhs: inout Vector, rhs: Vector) {
         lhs.x -= rhs.x
         lhs.y -= rhs.y
     }
     
     static func *= (lhs: inout Vector, rhs: Double) {
         lhs.x *= rhs
         lhs.y *= rhs
     }

     static func /= (lhs: inout Vector, rhs: Double) {
         lhs.x /= rhs
         lhs.y /= rhs
     }
     
     static prefix func - (rhs: Vector) -> Vector {
         return Vector(x: -rhs.x, y: -rhs.y)
     }
    
    var length: Double {
        (x*x + y*y).squareRoot()
    }
}
