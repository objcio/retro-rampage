//
//  ViewController.swift
//  RetroRampage
//
//  Created by Chris Eidhof on 05.12.19.
//  Copyright © 2019 Chris Eidhof. All rights reserved.
//

import UIKit

func loadMap() -> Tilemap {
    let url = Bundle.main.url(forResource: "map", withExtension: "json")!
    let data = try! Data(contentsOf: url)
    return try! JSONDecoder().decode(Tilemap.self, from: data)
}

class ViewController: UIViewController {
    let imageView = UIImageView()
    let panRecognizer = UIPanGestureRecognizer()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpImageView()
        view.addGestureRecognizer(panRecognizer)
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)
    }
    
    var world = World(player: Player(position: Vector(x: 4, y: 4), velocity: Vector(x: 0, y: 0)), map: loadMap())
    var previousTime: Double = CACurrentMediaTime()
    
    var joystickVector: Vector {
        let translation = panRecognizer.translation(in: view)
        return Vector(x: Double(translation.x), y: Double(translation.y)) / 40
    }
    
    @objc func update(_ displayLink: CADisplayLink) {
        var renderer = Renderer(width: 256, height: 256)
        let timestep = displayLink.timestamp - previousTime
        world.update(timestep: timestep, input: joystickVector)
        renderer.draw(world: world)
        previousTime = displayLink.timestamp
        imageView.image = UIImage(bitmap: renderer.bitmap)
    }
}

struct Player {
    var position: Vector
    var velocity: Vector
    let radius: Double = 0.5
    
    mutating func update(timestep: Double, input: Vector) {
        velocity = input
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
        bitmap = Bitmap(width: width, height: height, color: .black)
    }
    
    mutating func draw(world: World) {
        let worldWidth = 8.0
        let scale = Double(bitmap.width) / worldWidth
        
        for y in 0..<world.map.height {
            for x in 0..<world.map.width {
                guard world.map[x, y].isWall else { continue }
                let min = Vector(x: Double(x) * scale, y: Double(y) * scale)
                let rect = Rect(
                    min: min,
                    max: min + Vector(x: scale, y: scale)
                )
                bitmap.fill(rect: rect, color: .white)
            }
        }
        
        bitmap.fill(rect: world.player.rect * scale, color: .blue)
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

enum Tile: Int, Decodable {
    case nothing = 0
    case wall = 1
    
    var isWall: Bool {
        switch self {
        case .wall: return true
        case .nothing: return false
        }
    }
}

struct Tilemap: Decodable {
    let width: Int
    let tiles: [Tile]
    
    subscript(x: Int, y: Int) -> Tile {
        tiles[y*width + x]
    }
    
    var height: Int {
        tiles.count / width
    }
}

struct World {
    var player: Player
    var map: Tilemap
    
    mutating func update(timestep: Double, input: Vector) {
        player.update(timestep: timestep, input: input)
    }
}
