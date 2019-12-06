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

let joystickRadius = 40.0

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
    
    var world = World(player: Player(position: Vector(x: 2.5, y: 2.5), velocity: Vector(x: 0, y: 0), direction: Vector(x: 1, y: 0)), map: loadMap())
    var previousTime: Double = CACurrentMediaTime()
    
    var joystickVector: Vector {
        switch panRecognizer.state {
        case .began, .changed:
            let translation = panRecognizer.translation(in: view)
            let vector = Vector(x: Double(translation.x), y: Double(translation.y))
            let result = vector / max(joystickRadius, vector.length)
            panRecognizer.setTranslation(CGPoint(x: result.x * joystickRadius, y: result.y * joystickRadius), in: view)
            return result
        default:
            return Vector(x: 0, y: 0)
        }
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
    var direction: Vector
    let radius: Double = 0.25
    let speed: Double = 2
    
    mutating func update(timestep: Double, input: Vector) {
        if input.length > 0 {
            direction = input / input.length
        }
        velocity = input * speed
        position += velocity * timestep
        position.x.formTruncatingRemainder(dividingBy: 8) // todo
        position.y.formTruncatingRemainder(dividingBy: 8) // todo
    }
    
    var rect: Rect {
        let half = Vector(x: radius, y: radius)
        return Rect(min: position - half, max: position + half)
    }
    
    func intersection(with map: Tilemap) -> Vector? {
        let playerRect = self.rect
        let minX = Int(playerRect.min.x)
        let minY = Int(playerRect.min.y)
        let maxX = Int(playerRect.max.x)
        let maxY = Int(playerRect.max.y)
        var largestIntersection: Vector? = nil
        for y in minY...maxY {
            for x in minX...maxX {
                let min = Vector(x: Double(x), y: Double(y))
                let wallRect = Rect(min: min, max: min + Vector(x: 1, y: 1))
                if map[x,y].isWall, let intersection = wallRect.intersection(with: playerRect) {
                    if intersection.length > (largestIntersection?.length ?? 0) {
                        largestIntersection = intersection
                    }
                }
            }
        }
        return largestIntersection
    }
}

extension Rect {
    func intersection(with other: Rect) -> Vector? {
        let left = Vector(x: max.x - other.min.x, y: 0)
        if left.x <= 0 { return nil }
        let right = Vector(x: min.x - other.max.x, y: 0)
        if right.x >= 0 { return nil}
        let top = Vector(x: 0, y: max.y - other.min.y)
        if top.y <= 0 { return nil }
        let bottom = Vector(x: 0, y: min.y - other.max.y)
        if bottom.y >= 0 { return nil }
        return [left, right, top, bottom].sorted(by: { $0.length < $1.length }).first
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
        let end = (world.player.position + world.player.direction * 100) * scale
        bitmap.drawLine(from: world.player.position * scale, to: end, color: .green)
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
    
    mutating func drawLine(from: Vector, to: Vector, color: Color) {
        let difference = to - from
        let stepCount: Int
        let step: Vector
        if abs(difference.x) > abs(difference.y) {
            stepCount = Int(abs(difference.x).rounded(.up))
            let sign: Double = difference.x > 0 ? 1 : -1
            step = Vector(x: 1, y: difference.y/difference.x) * sign
        } else {
            stepCount = Int(abs(difference.y).rounded(.up))
            let sign: Double = difference.y > 0 ? 1 : -1
            step = Vector(x: difference.x/difference.y, y: 1) * sign
        }
        var position = from
        for _ in 0..<stepCount {
            self[Int(position.x), Int(position.y)] = color
            position += step
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
        while let intersection = player.intersection(with: map) {
            player.position += intersection
        }
    }
}
