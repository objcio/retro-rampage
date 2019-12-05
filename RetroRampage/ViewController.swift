//
//  ViewController.swift
//  RetroRampage
//
//  Created by Chris Eidhof on 05.12.19.
//  Copyright © 2019 Chris Eidhof. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let imageView = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpImageView()
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)
    }
    
    var player: Player = Player(position: Vector(x: 4, y: 4), velocity: Vector(x: 1, y: 1))
    var previousTime: Double = CACurrentMediaTime()
    
    @objc func update(_ displayLink: CADisplayLink) {
        let x = Int(displayLink.timestamp) % 8
        var renderer = Renderer(width: 256, height: 256)
        renderer.draw(player: player)
        let timestep = displayLink.timestamp - previousTime
        player.update(timestep: timestep)
        previousTime = displayLink.timestamp
        imageView.image = UIImage(bitmap: renderer.bitmap)
    }
}

struct Player {
    var position: Vector
    var velocity: Vector
    let radius: Double = 0.5
    
    mutating func update(timestep: Double) {
        position += velocity * timestep
        position.x.formTruncatingRemainder(dividingBy: 8) // todo
        position.y.formTruncatingRemainder(dividingBy: 8) // todo
    }
    
    var rect: Rect {
        let half = Vector(x: radius, y: radius)
        return Rect(min: position - half, max: position + half)
    }
}

struct Vector {
    var x: Double
    var y: Double
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
}

struct Color {
    var r, g, b: UInt8
    var a: UInt8 = 255
}

struct Bitmap {
    let width: Int
    var pixels: [Color]
    
    var height: Int {
        pixels.count / width
    }
    
    subscript(x: Int, y: Int) -> Color {
        get { pixels[y * width + x] }
        set {
            guard y < height, x < width, y >= 0, x >= 0 else { return }
            pixels[y * width + x] = newValue
        }
    }
    
    init(width: Int, height: Int, color: Color) {
        self.width = width
        pixels = Array(repeating: color, count: width * height)
    }
}

struct Renderer {
    var bitmap: Bitmap
    init(width: Int, height: Int) {
        bitmap = Bitmap(width: width, height: height, color: .white)
    }
    
    mutating func draw(player: Player) {
        let worldWidth = 8.0
        let worldHeight = 8.0
        let scale = Double(bitmap.width) / worldWidth
        bitmap.fill(rect: player.rect * scale, color: .blue)
    }
}

struct Rect {
    var min: Vector
    var max: Vector
    
    static func *(lhs: Rect, scale: Double) -> Rect {
        return Rect(min: lhs.min * scale, max: lhs.max * scale)
    }
}

extension Bitmap {
    mutating func fill(rect: Rect, color: Color) {
        for y in Int(rect.min.y)..<Int(rect.max.y) {
            for x in Int(rect.min.x)..<Int(rect.max.x) {
                self[x, y] = color
            }
        }
    }
}
