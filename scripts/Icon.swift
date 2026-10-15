import AppKit
let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for (size, suffix) in [(16,"16x16"),(32,"16x16@2x"),(32,"32x32"),(64,"32x32@2x"),(128,"128x128"),(256,"128x128@2x"),(256,"256x256"),(512,"256x256@2x"),(512,"512x512"),(1024,"512x512@2x")] {
    let n = CGFloat(size)
    let image = NSImage(size: NSSize(width: n, height: n))
    image.lockFocus()
    let bg = NSBezierPath(roundedRect: NSRect(x: n*0.06, y: n*0.06, width: n*0.88, height: n*0.88), xRadius: n*0.20, yRadius: n*0.20)
    NSGradient(starting: NSColor(red: 0.07, green: 0.68, blue: 0.63, alpha: 1), ending: NSColor(red: 0.04, green: 0.36, blue: 0.42, alpha: 1))!.draw(in: bg, angle: -65)
    let p = NSBezierPath()
    p.move(to: NSPoint(x: n*0.29, y: n*0.54)); p.line(to: NSPoint(x: n*0.32, y: n*0.26)); p.line(to: NSPoint(x: n*0.68, y: n*0.26)); p.line(to: NSPoint(x: n*0.71, y: n*0.54))
    p.lineWidth = n*0.055; p.lineCapStyle = .round; p.lineJoinStyle = .round
    NSColor.white.setStroke(); p.stroke()
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: n*0.5, y: n*0.47)); arrow.line(to: NSPoint(x: n*0.5, y: n*0.76))
    arrow.move(to: NSPoint(x: n*0.38, y: n*0.64)); arrow.line(to: NSPoint(x: n*0.5, y: n*0.76)); arrow.line(to: NSPoint(x: n*0.62, y: n*0.64))
    arrow.lineWidth = n*0.055; arrow.lineCapStyle = .round; arrow.lineJoinStyle = .round; arrow.stroke()
    image.unlockFocus()
    let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
    try rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("icon_\(suffix).png"))
}
