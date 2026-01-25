import SwiftUI

// MARK: - Code Block View (syntax highlighted, VSCode-style)

struct CodeBlockView: View {
    let code: String
    let language: String
    @State private var copied = false

    // VSCode Dark+ inspired colors
    private let bgColor = Color(red: 0.12, green: 0.12, blue: 0.14) // #1e1e23
    private let headerBg = Color(red: 0.15, green: 0.15, blue: 0.17) // #262628
    private let borderColor = Color.white.opacity(0.06)
    private let gutterColor = Color.white.opacity(0.2)

    // Syntax colors (VSCode Dark+)
    private let keywordColor = Color(red: 0.34, green: 0.61, blue: 0.84)   // #569cd6 - blue
    private let stringColor = Color(red: 0.81, green: 0.54, blue: 0.37)    // #ce9178 - orange
    private let commentColor = Color(red: 0.42, green: 0.56, blue: 0.35)   // #6a9955 - green
    private let numberColor = Color(red: 0.71, green: 0.81, blue: 0.65)    // #b5cea8 - light green
    private let typeColor = Color(red: 0.31, green: 0.78, blue: 0.78)      // #4ec9b0 - teal
    private let funcColor = Color(red: 0.86, green: 0.86, blue: 0.67)      // #dcdcab - yellow
    private let defaultColor = Color(red: 0.85, green: 0.85, blue: 0.85)   // #d4d4d4 - light gray
    private let paramColor = Color(red: 0.61, green: 0.75, blue: 0.93)     // #9cdcfe - light blue
    private let punctuationColor = Color.white.opacity(0.5)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack {
                Text(language.isEmpty ? "code" : language.lowercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                        Text(copied ? "Copied!" : "Copy")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(copied ? 0.7 : 0.4))
                }
                .buttonStyle(.plain)
                .pointerCursor()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(headerBg)

            // Code content with line numbers
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers
                    let lines = code.components(separatedBy: "\n")
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(0..<lines.count, id: \.self) { i in
                            Text("\(i + 1)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(gutterColor)
                                .frame(height: 20)
                        }
                    }
                    .padding(.leading, 14)
                    .padding(.trailing, 12)
                    .padding(.vertical, 12)

                    // Gutter separator
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 1)
                        .padding(.vertical, 8)

                    // Highlighted code
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<lines.count, id: \.self) { i in
                            highlightedLine(lines[i])
                                .frame(height: 20, alignment: .leading)
                        }
                    }
                    .padding(.leading, 14)
                    .padding(.trailing, 14)
                    .padding(.vertical, 12)
                }
            }
            .textSelection(.enabled)
        }
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Syntax Highlighting

    private func highlightedLine(_ line: String) -> Text {
        let lang = language.lowercased()
        let tokens = tokenizeLine(line, language: lang)
        var attributed = AttributedString()
        for token in tokens {
            let color = colorForTokenType(token.type)
            var part = AttributedString(token.text)
            part.font = .system(size: 12, design: .monospaced)
            part.foregroundColor = color
            attributed.append(part)
        }
        return Text(attributed)
    }

    private struct SyntaxToken {
        let text: String
        let type: TokenType
    }

    private enum TokenType {
        case keyword
        case string
        case comment
        case number
        case type
        case function
        case parameter
        case punctuation
        case plain
    }

    private func colorForTokenType(_ type: TokenType) -> Color {
        switch type {
        case .keyword: return keywordColor
        case .string: return stringColor
        case .comment: return commentColor
        case .number: return numberColor
        case .type: return typeColor
        case .function: return funcColor
        case .parameter: return paramColor
        case .punctuation: return punctuationColor
        case .plain: return defaultColor
        }
    }

    private func tokenizeLine(_ line: String, language: String) -> [SyntaxToken] {
        if line.isEmpty { return [SyntaxToken(text: " ", type: .plain)] }

        let keywords = keywordsForLanguage(language)
        let typeWords = typeWordsForLanguage(language)

        // Build regex pattern for tokenization
        // Order: comments, strings, numbers, words, punctuation, whitespace
        let patterns: [(String, TokenType)] = [
            (#"//.*$|#.*$"#, .comment),                          // line comments
            (#"/\*.*?\*/"#, .comment),                            // block comments
            (#""""(?:[^"\\]|\\.)*"""#, .string),                  // double-quoted strings
            (#"'(?:[^'\\]|\\.)*'"#, .string),                     // single-quoted strings
            (#"\b\d+\.?\d*\b"#, .number),                         // numbers
            (#"\b[A-Za-z_]\w*(?=\s*\()"#, .function),            // function calls
            (#"\b[A-Za-z_]\w*"#, .plain),                         // identifiers (will reclassify)
            (#"[{}()\[\];:,.=+\-*/<>!&|?@%^~]"#, .punctuation),  // punctuation
            (#"\s+"#, .plain),                                     // whitespace
        ]

        var tokens: [SyntaxToken] = []
        var remaining = line

        while !remaining.isEmpty {
            var matched = false

            for (pattern, defaultType) in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
                let nsRange = NSRange(remaining.startIndex..., in: remaining)
                guard let match = regex.firstMatch(in: remaining, options: .anchored, range: nsRange),
                      let range = Range(match.range, in: remaining) else { continue }

                let matchText = String(remaining[range])
                var tokenType = defaultType

                // Reclassify identifiers
                if defaultType == .plain && matchText.first?.isLetter == true {
                    if keywords.contains(matchText) {
                        tokenType = .keyword
                    } else if typeWords.contains(matchText) || (matchText.first?.isUppercase == true && matchText.count > 1) {
                        tokenType = .type
                    }
                }

                tokens.append(SyntaxToken(text: matchText, type: tokenType))
                remaining = String(remaining[range.upperBound...])
                matched = true
                break
            }

            if !matched {
                // Take one character as plain text
                tokens.append(SyntaxToken(text: String(remaining.first!), type: .plain))
                remaining = String(remaining.dropFirst())
            }
        }

        return tokens
    }

    private func keywordsForLanguage(_ lang: String) -> Set<String> {
        switch lang {
        case "swift":
            return ["import", "func", "var", "let", "if", "else", "for", "while", "return", "class", "struct", "enum", "protocol", "extension", "guard", "switch", "case", "default", "break", "continue", "throw", "throws", "try", "catch", "do", "in", "self", "Self", "true", "false", "nil", "private", "public", "internal", "fileprivate", "open", "static", "override", "init", "deinit", "where", "as", "is", "async", "await", "some", "any", "typealias", "associatedtype", "weak", "unowned", "lazy", "mutating", "nonmutating", "convenience", "required", "final", "inout", "defer", "repeat"]
        case "javascript", "js", "typescript", "ts", "jsx", "tsx":
            return ["const", "let", "var", "function", "return", "if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "class", "extends", "import", "export", "from", "async", "await", "try", "catch", "throw", "new", "this", "super", "typeof", "instanceof", "in", "of", "true", "false", "null", "undefined", "yield", "delete", "void", "interface", "type", "enum", "implements", "abstract", "readonly", "private", "public", "protected", "static", "constructor"]
        case "python", "py":
            return ["def", "class", "if", "elif", "else", "for", "while", "return", "import", "from", "as", "try", "except", "finally", "raise", "with", "yield", "lambda", "pass", "break", "continue", "and", "or", "not", "in", "is", "True", "False", "None", "self", "async", "await", "global", "nonlocal", "del", "assert"]
        case "html", "xml":
            return []
        case "css", "scss", "sass":
            return ["important", "inherit", "initial", "unset", "none", "auto", "block", "inline", "flex", "grid", "absolute", "relative", "fixed", "sticky"]
        case "json":
            return ["true", "false", "null"]
        case "rust", "rs":
            return ["fn", "let", "mut", "if", "else", "for", "while", "loop", "return", "match", "struct", "enum", "impl", "trait", "use", "mod", "pub", "crate", "self", "super", "as", "in", "ref", "move", "async", "await", "true", "false", "where", "type", "const", "static", "unsafe", "extern"]
        case "go":
            return ["func", "var", "const", "if", "else", "for", "range", "return", "switch", "case", "default", "break", "continue", "type", "struct", "interface", "map", "chan", "go", "defer", "select", "package", "import", "true", "false", "nil"]
        case "java", "kotlin", "kt":
            return ["class", "interface", "extends", "implements", "public", "private", "protected", "static", "final", "abstract", "void", "int", "long", "double", "float", "boolean", "char", "byte", "short", "new", "return", "if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "try", "catch", "finally", "throw", "throws", "import", "package", "this", "super", "true", "false", "null", "val", "var", "fun", "when", "object", "companion", "data", "sealed", "override", "open", "lateinit", "suspend"]
        case "bash", "sh", "shell", "zsh":
            return ["if", "then", "else", "elif", "fi", "for", "while", "do", "done", "case", "esac", "function", "return", "exit", "echo", "export", "source", "local", "readonly", "in", "true", "false"]
        default:
            // Generic keywords
            return ["if", "else", "for", "while", "return", "function", "class", "import", "export", "var", "let", "const", "true", "false", "null", "nil", "self", "this", "new", "try", "catch", "throw", "switch", "case", "default", "break", "continue", "do", "in", "of", "async", "await", "public", "private", "static", "void", "int", "string", "bool", "float", "double"]
        }
    }

    private func typeWordsForLanguage(_ lang: String) -> Set<String> {
        switch lang {
        case "swift":
            return ["String", "Int", "Double", "Float", "Bool", "Array", "Dictionary", "Set", "Optional", "Any", "AnyObject", "Void", "Never", "Error", "Codable", "Hashable", "Equatable", "Comparable", "Identifiable", "ObservableObject", "Published", "State", "Binding", "View", "Color", "Text", "Image", "Button", "VStack", "HStack", "ZStack", "List", "ForEach", "NavigationView", "ScrollView", "CGFloat", "CGPoint", "CGSize", "CGRect", "NSFont", "NSColor", "URL", "Data", "Date", "Result", "AttributedString"]
        case "javascript", "js", "typescript", "ts", "jsx", "tsx":
            return ["String", "Number", "Boolean", "Object", "Array", "Map", "Set", "Promise", "Date", "Error", "RegExp", "Symbol", "BigInt", "Function", "Proxy", "Reflect", "JSON", "Math", "console", "document", "window", "HTMLElement", "React", "Component"]
        case "python", "py":
            return ["str", "int", "float", "bool", "list", "dict", "tuple", "set", "bytes", "type", "object", "Exception", "print", "len", "range", "enumerate", "zip", "map", "filter"]
        default:
            return ["String", "Int", "Integer", "Float", "Double", "Boolean", "Bool", "Array", "List", "Map", "Set", "Object", "Error", "Exception", "void", "null"]
        }
    }
}
