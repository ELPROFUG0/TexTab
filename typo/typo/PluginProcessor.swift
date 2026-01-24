//
//  PluginProcessor.swift
//  typo
//

import Foundation
import CoreImage
import AppKit
import CryptoKit

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
        case .jsonFormatter:
            return formatJSON(input)
        case .base64Encode:
            return base64Encode(input)
        case .base64Decode:
            return base64Decode(input)
        case .colorConverter:
            return convertColor(input)
        case .uuidGenerator:
            return generateUUID()
        case .hashGenerator:
            return generateHashes(from: input)
        case .urlEncode:
            return urlEncode(input)
        case .urlDecode:
            return urlDecode(input)
        case .wordCount:
            return countWords(input)
        case .imageConverter:
            return .error("Use processImageConversion for image converter")
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

    // MARK: - JSON Formatter

    private func formatJSON(_ input: String) -> PluginResult {
        guard let data = input.data(using: .utf8) else {
            return .error("Invalid input")
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            let prettyData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])

            guard let prettyString = String(data: prettyData, encoding: .utf8) else {
                return .error("Failed to format JSON")
            }

            return .text(prettyString)
        } catch {
            return .error("Invalid JSON: \(error.localizedDescription)")
        }
    }

    // MARK: - Base64 Encode/Decode

    private func base64Encode(_ input: String) -> PluginResult {
        guard let data = input.data(using: .utf8) else {
            return .error("Failed to encode text")
        }

        let encoded = data.base64EncodedString()
        return .text(encoded)
    }

    private func base64Decode(_ input: String) -> PluginResult {
        // Remove whitespace and newlines
        let cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = Data(base64Encoded: cleanInput) else {
            return .error("Invalid Base64 string")
        }

        guard let decoded = String(data: data, encoding: .utf8) else {
            return .error("Failed to decode as UTF-8 text")
        }

        return .text(decoded)
    }

    // MARK: - Color Converter

    private func convertColor(_ input: String) -> PluginResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to parse as HEX
        if let (r, g, b) = parseHex(trimmed) {
            let hsl = rgbToHSL(r: r, g: g, b: b)
            return .text("""
HEX: \(formatHex(r: r, g: g, b: b))
RGB: rgb(\(r), \(g), \(b))
HSL: hsl(\(hsl.h), \(hsl.s)%, \(hsl.l)%)
Swift: Color(red: \(Double(r)/255.0), green: \(Double(g)/255.0), blue: \(Double(b)/255.0))
""")
        }

        // Try to parse as RGB
        if let (r, g, b) = parseRGB(trimmed) {
            let hsl = rgbToHSL(r: r, g: g, b: b)
            return .text("""
HEX: \(formatHex(r: r, g: g, b: b))
RGB: rgb(\(r), \(g), \(b))
HSL: hsl(\(hsl.h), \(hsl.s)%, \(hsl.l)%)
Swift: Color(red: \(Double(r)/255.0), green: \(Double(g)/255.0), blue: \(Double(b)/255.0))
""")
        }

        return .error("Could not parse color. Try formats: #FF5733, rgb(255, 87, 51), or 255,87,51")
    }

    private func parseHex(_ hex: String) -> (Int, Int, Int)? {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanHex = cleanHex.replacingOccurrences(of: "#", with: "")

        guard cleanHex.count == 6, let hexValue = Int(cleanHex, radix: 16) else {
            return nil
        }

        let r = (hexValue >> 16) & 0xFF
        let g = (hexValue >> 8) & 0xFF
        let b = hexValue & 0xFF

        return (r, g, b)
    }

    private func parseRGB(_ input: String) -> (Int, Int, Int)? {
        // Match rgb(r, g, b) or r, g, b or r g b
        let pattern = #"(\d{1,3})[,\s]+(\d{1,3})[,\s]+(\d{1,3})"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
              let rRange = Range(match.range(at: 1), in: input),
              let gRange = Range(match.range(at: 2), in: input),
              let bRange = Range(match.range(at: 3), in: input),
              let r = Int(input[rRange]),
              let g = Int(input[gRange]),
              let b = Int(input[bRange]),
              (0...255).contains(r), (0...255).contains(g), (0...255).contains(b) else {
            return nil
        }

        return (r, g, b)
    }

    private func formatHex(r: Int, g: Int, b: Int) -> String {
        return String(format: "#%02X%02X%02X", r, g, b)
    }

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

    // MARK: - UUID Generator

    private func generateUUID() -> PluginResult {
        let uuid = UUID()
        return .text("""
UUID: \(uuid.uuidString)
Lowercase: \(uuid.uuidString.lowercased())
No dashes: \(uuid.uuidString.replacingOccurrences(of: "-", with: ""))
""")
    }

    // MARK: - Hash Generator

    private func generateHashes(from input: String) -> PluginResult {
        guard let data = input.data(using: .utf8) else {
            return .error("Failed to encode text")
        }

        let md5 = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let sha256 = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let sha512 = SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()

        return .text("""
MD5: \(md5)
SHA-256: \(sha256)
SHA-512: \(sha512)
""")
    }

    // MARK: - URL Encode/Decode

    private func urlEncode(_ input: String) -> PluginResult {
        guard let encoded = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return .error("Failed to URL encode")
        }
        return .text(encoded)
    }

    private func urlDecode(_ input: String) -> PluginResult {
        guard let decoded = input.removingPercentEncoding else {
            return .error("Failed to URL decode")
        }
        return .text(decoded)
    }

    // MARK: - Word Count

    private func countWords(_ input: String) -> PluginResult {
        let words = input.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        let characters = input.count
        let charactersNoSpaces = input.filter { !$0.isWhitespace && !$0.isNewline }.count
        let lines = input.components(separatedBy: .newlines).count
        let sentences = input.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        let paragraphs = input.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        return .text("""
Words: \(words)
Characters: \(characters)
Characters (no spaces): \(charactersNoSpaces)
Lines: \(lines)
Sentences: \(sentences)
Paragraphs: \(paragraphs)
""")
    }
}
