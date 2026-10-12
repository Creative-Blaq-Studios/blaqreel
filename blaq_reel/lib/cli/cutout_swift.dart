/// The Swift tool `blaq_reel media cutout` compiles and runs on macOS: it
/// lifts a subject out of a photo with the Vision framework (no downloads),
/// shapes the mask, and writes a cut-out PNG.
///
/// Arguments, in order: input, output, subject (`person` or `object`),
/// region (fractions `x,y x,y …`, or `-`), solid (`1`/`0`), fade edges
/// (letters of `lrtb`, or `-`), drop dark (`1`/`0`), tip direction (`up`,
/// `up-left`, `left`, …, or `-`). It prints one line of JSON:
/// `{"width", "height", "tip": [x, y]}`.
const cutoutSwift = r'''
import Foundation
import Vision
import CoreImage
import AppKit

let a = CommandLine.arguments
guard a.count >= 9 else { print("usage: cutout in out subject region solid fade dark tip"); exit(2) }
let (input, output, subject, regionArg, solid, fadeArg, dropDark, tipArg) =
  (a[1], a[2], a[3], a[4], a[5] == "1", a[6], a[7] == "1", a[8])

guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: input) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
  FileHandle.standardError.write("can't read \(input)\n".data(using: .utf8)!); exit(1)
}
let W = image.width, H = image.height

// The photo as RGBA bytes.
var rgba = [UInt8](repeating: 0, count: W * H * 4)
let space = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: &rgba, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4,
                    space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(image, in: CGRect(x: 0, y: 0, width: W, height: H))

// The subject's mask, at the photo's size, 0...1, top row first.
func maskOf(_ buffer: CVPixelBuffer) -> [Float] {
  let ci = CIImage(cvPixelBuffer: buffer)
  let sx = CGFloat(W) / ci.extent.width, sy = CGFloat(H) / ci.extent.height
  let scaled = ci.transformed(by: CGAffineTransform(scaleX: sx, y: sy))
  var gray = [UInt8](repeating: 0, count: W * H)
  let g = CGContext(data: &gray, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W,
                    space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
  let cg = CIContext().createCGImage(scaled, from: CGRect(x: 0, y: 0, width: W, height: H))!
  g.draw(cg, in: CGRect(x: 0, y: 0, width: W, height: H))
  return gray.map { Float($0) / 255 }
}
let handler = VNImageRequestHandler(cgImage: image)
var mask: [Float]
if subject == "person" {
  let r = VNGeneratePersonSegmentationRequest(); r.qualityLevel = .accurate
  try handler.perform([r])
  guard let m = r.results?.first?.pixelBuffer else { print("{\"error\":\"no person found\"}"); exit(1) }
  mask = maskOf(m)
} else {
  let r = VNGenerateForegroundInstanceMaskRequest()
  try handler.perform([r])
  guard let res = r.results?.first else { print("{\"error\":\"no subject found\"}"); exit(1) }
  mask = maskOf(try res.generateScaledMaskForImage(forInstances: res.allInstances, from: handler))
}

// Keep only what is inside the region, a polygon in fractions of the photo.
if regionArg != "-" {
  let pts = regionArg.split(separator: " ").map { p -> (Double, Double) in
    let xy = p.split(separator: ",").map { Double($0)! }
    return (xy[0] * Double(W), xy[1] * Double(H))
  }
  func inside(_ x: Double, _ y: Double) -> Bool {
    var c = false
    var j = pts.count - 1
    for i in 0..<pts.count {
      let (xi, yi) = pts[i], (xj, yj) = pts[j]
      if (yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi { c.toggle() }
      j = i
    }
    return c
  }
  for y in 0..<H { for x in 0..<W where !inside(Double(x), Double(y)) { mask[y * W + x] = 0 } }
}
// Solid inside: a soft mask lets what is behind show through.
if solid { mask = mask.map { min(1, max(0, ($0 - 0.15) / 0.55)) } }
// Fade the edges where the photo cuts the subject off.
if fadeArg != "-" {
  for y in 0..<H { for x in 0..<W {
    var f: Float = 1
    if fadeArg.contains("r") { f *= min(1, Float(W - x) / (Float(W) * 0.04)) }
    if fadeArg.contains("l") { f *= min(1, Float(x) / (Float(W) * 0.04)) }
    if fadeArg.contains("b") { f *= min(1, Float(H - y) / (Float(H) * 0.05)) }
    if fadeArg.contains("t") { f *= min(1, Float(y) / (Float(H) * 0.05)) }
    mask[y * W + x] *= f
  } }
}
// Drop near-black, colourless pixels: a phone's frame, a dark edge.
if dropDark {
  for i in 0..<(W * H) {
    let r = Int(rgba[i * 4]), g = Int(rgba[i * 4 + 1]), b = Int(rgba[i * 4 + 2])
    let hi = max(r, g, b), lo = min(r, g, b)
    if hi < 70 && hi - lo < 22 { mask[i] = 0 }
  }
}

// The cut-out: the photo with the mask as its alpha, cropped to the subject.
var minX = W, minY = H, maxX = -1, maxY = -1
for y in 0..<H { for x in 0..<W where mask[y * W + x] > 0.03 {
  minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
} }
guard maxX >= minX else { print("{\"error\":\"nothing left after the mask\"}"); exit(1) }
let cw = maxX - minX + 1, chh = maxY - minY + 1
var out = [UInt8](repeating: 0, count: cw * chh * 4)
for y in 0..<chh { for x in 0..<cw {
  let s = (y + minY) * W + (x + minX), d = (y * cw + x) * 4
  let m = mask[s]
  // The photo was drawn premultiplied by its own (opaque) alpha: unpremultiply is a no-op.
  out[d] = UInt8(Float(rgba[s * 4]) * m); out[d + 1] = UInt8(Float(rgba[s * 4 + 1]) * m)
  out[d + 2] = UInt8(Float(rgba[s * 4 + 2]) * m); out[d + 3] = UInt8(m * 255)
} }
let oc = CGContext(data: &out, width: cw, height: chh, bitsPerComponent: 8, bytesPerRow: cw * 4,
                   space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let rep = NSBitmapImageRep(cgImage: oc.makeImage()!)
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))

// The fingertip: the solid pixel furthest in the tip's direction.
var tip = "null"
if tipArg != "-" {
  let dirs: [String: (Double, Double)] = ["up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0),
    "up-left": (-0.7, -0.7), "up-right": (0.7, -0.7), "down-left": (-0.7, 0.7), "down-right": (0.7, 0.7)]
  if let (dx, dy) = dirs[tipArg] {
    var best = -Double.infinity, bx = 0, by = 0
    for y in 0..<chh { for x in 0..<cw where out[(y * cw + x) * 4 + 3] > 200 {
      let v = Double(x) / Double(cw) * dx + Double(y) / Double(chh) * dy
      if v > best { best = v; bx = x; by = y }
    } }
    tip = String(format: "[%.3f, %.3f]", Double(bx) / Double(cw), Double(by) / Double(chh))
  }
}
print("{\"width\": \(cw), \"height\": \(chh), \"tip\": \(tip)}")
''';
