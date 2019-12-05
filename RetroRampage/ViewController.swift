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
    
    @objc func update(_ displayLink: CADisplayLink) {
        let x = Int(displayLink.timestamp) % 8
        var renderer = Renderer()
        renderer.draw(x: x)
        imageView.image = UIImage(bitmap: renderer.bitmap)
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
        set { pixels[y * width + x] = newValue }
    }
    
    init(width: Int, height: Int, color: Color) {
        self.width = width
        pixels = Array(repeating: color, count: width * height)
    }
}

struct Renderer {
    var bitmap = Bitmap(width: 8, height: 8, color: .white)
    
    mutating func draw(x: Int) {
        bitmap[x, 0] = Color.blue
    }
}
