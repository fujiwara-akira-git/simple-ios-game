#!/usr/bin/env swift
import AppKit
import Foundation

let fileManager = FileManager.default
let projectPath = "./SimpleGame/SimpleGame/Assets.xcassets/AppIcon.appiconset"

let images: [(String, Int)] = [
    ("AppIcon-1024.png", 1024),
    ("AppIcon-60@2x.png", 120),
    ("AppIcon-60@3x.png", 180),
    ("AppIcon-76@1x.png", 76),
    ("AppIcon-76@2x.png", 152),
    ("AppIcon-83.5@2x.png", 167),
    ("AppIcon-20@2x.png", 40),
    ("AppIcon-20@3x.png", 60),
    ("AppIcon-29@2x.png", 58),
    ("AppIcon-29@3x.png", 87)
]

func ensureFolder(_ path: String) {
    if !fileManager.fileExists(atPath: path) {
        try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    }
}

func drawBolt(in rect: CGRect, context: CGContext) {
    context.saveGState()
    let bolt = NSBezierPath()
    // simple lightning bolt shape relative to rect
    let w = rect.width
    let h = rect.height
    bolt.move(to: NSPoint(x: 0.55*w, y: 0.95*h))
    bolt.line(to: NSPoint(x: 0.25*w, y: 0.55*h))
    bolt.line(to: NSPoint(x: 0.46*w, y: 0.55*h))
    bolt.line(to: NSPoint(x: 0.35*w, y: 0.05*h))
    bolt.line(to: NSPoint(x: 0.75*w, y: 0.45*h))
    bolt.line(to: NSPoint(x: 0.54*w, y: 0.45*h))
    bolt.close()
    let color = NSColor.white
    color.setFill()
    bolt.fill()
    context.restoreGState()
}

func createImage(size: Int) -> NSImage? {
    let imageSize = NSSize(width: size, height: size)
    let image = NSImage(size: imageSize)
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { image.unlockFocus(); return nil }

    // draw background gradient: purple -> cyan
    let colors = [NSColor(red: 0.137, green: 0.0235, blue: 0.42, alpha: 1.0).cgColor,
                  NSColor(red: 0.0, green: 0.56, blue: 0.655, alpha: 1.0).cgColor]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0,1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x:0,y:0), end: CGPoint(x:CGFloat(size), y:CGFloat(size)), options: [])

    // draw subtle inner glow / rounded rect overlay
    ctx.setFillColor(NSColor(white: 1.0, alpha: 0.04).cgColor)
    let inset: CGFloat = CGFloat(size) * 0.06
    let rounded = CGPath(roundedRect: CGRect(x: inset, y: inset, width: CGFloat(size)-inset*2, height: CGFloat(size)-inset*2), cornerWidth: CGFloat(size)*0.12, cornerHeight: CGFloat(size)*0.12, transform: nil)
    ctx.addPath(rounded)
    ctx.fillPath()

    // draw bolt symbol in center
    let boltRect = CGRect(x: CGFloat(size)*0.2, y: CGFloat(size)*0.2, width: CGFloat(size)*0.6, height: CGFloat(size)*0.6)
    drawBolt(in: boltRect, context: ctx)

    image.unlockFocus()
    return image
}

ensureFolder(projectPath)

for (filename, size) in images {
    autoreleasepool {
        if let image = createImage(size: size) {
            if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
                let outPath = (projectPath as NSString).appendingPathComponent(filename)
                do {
                    try png.write(to: URL(fileURLWithPath: outPath))
                    print("Wrote \(outPath)")
                } catch {
                    print("Failed to write \(filename): \(error)")
                }
            }
        }
    }
}

print("Done. Generated \(images.count) app icon files in \(projectPath)")
