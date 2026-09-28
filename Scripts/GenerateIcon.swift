// Run from the repository root: swift Scripts/GenerateIcon.swift
import AppKit

let destination = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Tally Bar/Assets.xcassets/AppIcon.appiconset")
var entries: [[String: String]] = []
for pointSize in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let size = pointSize * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: bitmap)!
        NSGraphicsContext.current = context
        context.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
        NSColor(calibratedRed: 0.12, green: 0.23, blue: 0.23, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 200, yRadius: 200).fill()
        NSColor(calibratedRed: 0.94, green: 0.94, blue: 0.88, alpha: 1).setStroke()
        for x in [310, 445, 580, 715] {
            let mark = NSBezierPath()
            mark.lineWidth = 52
            mark.lineCapStyle = .round
            mark.move(to: NSPoint(x: x, y: 320))
            mark.line(to: NSPoint(x: x, y: 704))
            mark.stroke()
        }
        let slash = NSBezierPath()
        slash.lineWidth = 56
        slash.lineCapStyle = .round
        slash.move(to: NSPoint(x: 249, y: 394))
        slash.line(to: NSPoint(x: 775, y: 630))
        // An offset outline keeps the crossing tally legible at small sizes.
        NSColor(calibratedRed: 0.12, green: 0.23, blue: 0.23, alpha: 1).setStroke()
        slash.lineWidth = 86
        slash.stroke()
        NSColor(calibratedRed: 0.76, green: 0.87, blue: 0.61, alpha: 1).setStroke()
        slash.lineWidth = 52
        slash.stroke()
        NSGraphicsContext.restoreGraphicsState()
        let filename = "icon-\(pointSize)@\(scale)x.png"
        try bitmap.representation(using: .png, properties: [:])!.write(to: destination.appendingPathComponent(filename))
        entries.append(["idiom": "mac", "size": "\(pointSize)x\(pointSize)", "scale": "\(scale)x", "filename": filename])
    }
}
let catalog: [String: Any] = ["images": entries, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: catalog, options: [.prettyPrinted, .sortedKeys])
    .write(to: destination.appendingPathComponent("Contents.json"))
