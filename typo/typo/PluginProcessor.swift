//
//  PluginProcessor.swift
//  typo
//

import Foundation
import CoreImage
import AppKit

// MARK: - Image Format

enum ImageFormat: String, CaseIterable {
    case png = "PNG"
    case jpeg = "JPEG"
    case tiff = "TIFF"
    case gif = "GIF"
    case bmp = "BMP"
    case heic = "HEIC"

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .tiff: return "tiff"
        case .gif: return "gif"
        case .bmp: return "bmp"
        case .heic: return "heic"
        }
    }

    var bitmapType: NSBitmapImageRep.FileType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .tiff: return .tiff
        case .gif: return .gif
        case .bmp: return .bmp
        case .heic: return .png // Fallback, HEIC needs special handling
        }
    }
}

// MARK: - Plugin Result

enum PluginResult {
    case text(String)
    case image(NSImage)
    case imageData(Data, ImageFormat)
    case error(String)
}

// MARK: - Plugin Processor

class PluginProcessor {
    static let shared = PluginProcessor()

    func process(pluginType: PluginType, input: String) -> PluginResult {
        switch pluginType {
        case .qrGenerator:
            return generateQRCode(from: input)
        case .imageConverter:
            return .error("Use processImageConversion for image converter")
        case .colorPicker:
            return .error("Use pickColorFromScreen for color picker")
        }
    }

    // MARK: - Image Converter

    func getImageFromClipboard() -> NSImage? {
        let pasteboard = NSPasteboard.general
        let types = pasteboard.types ?? []

        // Get change count to verify clipboard has new content
        let changeCount = pasteboard.changeCount
        print("=== CLIPBOARD DEBUG ===")
        print("Clipboard change count: \(changeCount)")
        print("Clipboard types: \(types.map { $0.rawValue })")

        // Check if clipboard contains a file URL - this indicates a file was copied from Finder
        let hasFileURL = types.contains(.fileURL) || types.contains(NSPasteboard.PasteboardType("public.file-url"))

        // If there's a file URL, the TIFF data might just be the file's preview/icon
        // In this case, we should load the actual image file from the URL
        if hasFileURL {
            print("Clipboard contains file URL - checking for image file")
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
                for url in urls {
                    print("Found URL in clipboard: \(url.path)")
                    let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp"]
                    if imageExtensions.contains(url.pathExtension.lowercased()) {
                        if let image = NSImage(contentsOf: url) {
                            print("Loaded image from file URL: \(url.lastPathComponent)")
                            return image
                        }
                    }
                }
            }
            // If file URL exists but no image file found, still try image data below
            // (in case it's a file plus some image data)
        }

        // Priority 1: Try PNG data (screenshots and copied images from apps)
        if let imageData = pasteboard.data(forType: .png) {
            print("Found PNG data in clipboard (\(imageData.count) bytes)")
            if let image = NSImage(data: imageData) {
                return image
            }
        }

        // Priority 2: Try TIFF data - but only if there's no file URL
        // (file URLs often include TIFF preview data that's just the icon)
        if !hasFileURL, let imageData = pasteboard.data(forType: .tiff) {
            print("Found TIFF data in clipboard (\(imageData.count) bytes)")
            if let image = NSImage(data: imageData) {
                return image
            }
        }

        // Priority 3: Try JPEG
        if let imageData = pasteboard.data(forType: NSPasteboard.PasteboardType("public.jpeg")) {
            print("Found JPEG data in clipboard (\(imageData.count) bytes)")
            if let image = NSImage(data: imageData) {
                return image
            }
        }

        // Priority 4: Try generic NSImage (this often works for screenshots)
        // But skip if we have a file URL that isn't an image file
        if !hasFileURL {
            if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
                print("Found NSImage in clipboard")
                return image
            }
        }

        print("No image found in clipboard")
        return nil
    }

    func convertImage(_ image: NSImage, to format: ImageFormat, quality: Double = 0.9) -> PluginResult {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return .error("Failed to process image")
        }

        var properties: [NSBitmapImageRep.PropertyKey: Any] = [:]

        if format == .jpeg {
            properties[.compressionFactor] = quality
        }

        guard let data = bitmapRep.representation(using: format.bitmapType, properties: properties) else {
            return .error("Failed to convert image to \(format.rawValue)")
        }

        // Create NSImage from converted data
        guard let convertedImage = NSImage(data: data) else {
            return .error("Failed to create image from converted data")
        }

        return .imageData(data, format)
    }

    func getImageInfo(_ image: NSImage) -> String {
        let size = image.size
        var info = "Size: \(Int(size.width)) x \(Int(size.height)) pixels"

        if let tiffData = image.tiffRepresentation {
            let sizeKB = Double(tiffData.count) / 1024.0
            if sizeKB > 1024 {
                info += "\nOriginal size: \(String(format: "%.1f", sizeKB / 1024.0)) MB"
            } else {
                info += "\nOriginal size: \(String(format: "%.1f", sizeKB)) KB"
            }
        }

        return info
    }

    // MARK: - QR Code Generator

    private func generateQRCode(from string: String) -> PluginResult {
        guard let data = string.data(using: .utf8) else {
            return .error("Failed to encode text")
        }

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return .error("QR Code generator not available")
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction

        guard let ciImage = filter.outputImage else {
            return .error("Failed to generate QR code")
        }

        // Scale up the QR code for better quality
        let scale = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: scale)

        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        return .image(nsImage)
    }

    // MARK: - Color Picker

    func pickColorFromScreen(completion: @escaping (PluginResult) -> Void) {
        let sampler = NSColorSampler()
        sampler.show { selectedColor in
            guard let color = selectedColor else {
                completion(.error("Color picking cancelled"))
                return
            }

            // Convert to sRGB - the standard color space for web and most code
            guard let srgbColor = color.usingColorSpace(.sRGB) else {
                completion(.error("Failed to convert color"))
                return
            }

            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            srgbColor.getRed(&r, green: &g, blue: &b, alpha: &a)

            // Convert to 0-255 with standard rounding
            let rInt = Int(round(r * 255.0))
            let gInt = Int(round(g * 255.0))
            let bInt = Int(round(b * 255.0))

            // Clamp to valid range
            let rClamped = max(0, min(255, rInt))
            let gClamped = max(0, min(255, gInt))
            let bClamped = max(0, min(255, bInt))

            let hex = String(format: "#%02X%02X%02X", rClamped, gClamped, bClamped)
            let hsl = self.rgbToHSL(r: rClamped, g: gClamped, b: bClamped)

            let result = """
HEX: \(hex)
RGB: rgb(\(rClamped), \(gClamped), \(bClamped))
HSL: hsl(\(hsl.h), \(hsl.s)%, \(hsl.l)%)
Swift: Color(red: \(String(format: "%.4f", r)), green: \(String(format: "%.4f", g)), blue: \(String(format: "%.4f", b)))
UIKit: UIColor(red: \(String(format: "%.4f", r)), green: \(String(format: "%.4f", g)), blue: \(String(format: "%.4f", b)), alpha: 1.0)
CSS: rgba(\(rClamped), \(gClamped), \(bClamped), 1.0)
"""
            completion(.text(result))
        }
    }

    // MARK: - RGB to HSL Helper (for Color Picker)

    private func rgbToHSL(r: Int, g: Int, b: Int) -> (h: Int, s: Int, l: Int) {
        let r1 = Double(r) / 255.0
        let g1 = Double(g) / 255.0
        let b1 = Double(b) / 255.0

        let maxC = max(r1, g1, b1)
        let minC = min(r1, g1, b1)
        let delta = maxC - minC

        var h: Double = 0
        var s: Double = 0
        let l = (maxC + minC) / 2

        if delta != 0 {
            s = l > 0.5 ? delta / (2 - maxC - minC) : delta / (maxC + minC)

            if maxC == r1 {
                h = ((g1 - b1) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxC == g1 {
                h = (b1 - r1) / delta + 2
            } else {
                h = (r1 - g1) / delta + 4
            }

            h *= 60
            if h < 0 { h += 360 }
        }

        return (Int(h.rounded()), Int((s * 100).rounded()), Int((l * 100).rounded()))
    }
}
