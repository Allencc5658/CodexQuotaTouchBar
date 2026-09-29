import AppKit

// Run with: swiftc -framework AppKit generate-icon.swift -o generate-icon
//           ./generate-icon AppIcon-1024.png
let destination = CommandLine.arguments[1]
let side = 1024
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not create icon bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: side, height: side).fill()

let tile = NSBezierPath(roundedRect: NSRect(x: 72, y: 72, width: 880, height: 880),
                        xRadius: 198, yRadius: 198)
let shadow = NSShadow()
shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.28)
shadow.shadowBlurRadius = 40
shadow.shadowOffset = NSSize(width: 0, height: -18)
shadow.set()
NSGradient(starting: NSColor(calibratedRed: 0.055, green: 0.11, blue: 0.20, alpha: 1),
           ending: NSColor(calibratedRed: 0.04, green: 0.34, blue: 0.39, alpha: 1))!
    .draw(in: tile, angle: 115)
NSShadow().set()

let rim = NSBezierPath(roundedRect: NSRect(x: 91, y: 91, width: 842, height: 842),
                       xRadius: 181, yRadius: 181)
rim.lineWidth = 5
NSColor(calibratedWhite: 1, alpha: 0.16).setStroke()
rim.stroke()

// A clear Q shape remains readable at Launchpad sizes. The two rows inside
// the ring echo the five-hour and weekly segmented quota displays.
let ring = NSBezierPath(ovalIn: NSRect(x: 247, y: 278, width: 530, height: 530))
ring.lineWidth = 76
NSColor(calibratedWhite: 1, alpha: 0.93).setStroke()
ring.stroke()

let tail = NSBezierPath()
tail.move(to: NSPoint(x: 673, y: 372))
tail.line(to: NSPoint(x: 798, y: 253))
tail.lineWidth = 78
tail.lineCapStyle = .round
NSColor(calibratedWhite: 1, alpha: 0.95).setStroke()
tail.stroke()

func drawSegments(y: CGFloat, filled: Int, color: NSColor) {
    for index in 0..<8 {
        let frame = NSRect(x: 326 + CGFloat(index) * 47, y: y, width: 35, height: 37)
        let segment = NSBezierPath(roundedRect: frame, xRadius: 10, yRadius: 10)
        (index < filled ? color : NSColor(calibratedWhite: 1, alpha: 0.23)).setFill()
        segment.fill()
    }
}

drawSegments(y: 576, filled: 6,
             color: NSColor(calibratedRed: 0.34, green: 0.95, blue: 0.78, alpha: 1))
drawSegments(y: 478, filled: 4,
             color: NSColor(calibratedRed: 0.36, green: 0.76, blue: 1, alpha: 1))

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
guard let data = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode icon")
}
try data.write(to: URL(fileURLWithPath: destination))
