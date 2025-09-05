import Foundation
import AppKit

class BatchImportService {
    static let shared = BatchImportService()
    
    private init() {}
    
    // URL validation patterns
    private let urlPatterns = [
        "^https?://",
        "^(www\\.)?youtube\\.com",
        "^(www\\.)?youtu\\.be",
        "^(www\\.)?vimeo\\.com",
        "^(www\\.)?twitter\\.com",
        "^(www\\.)?x\\.com",
        "^(www\\.)?instagram\\.com",
        "^(www\\.)?tiktok\\.com",
        "^(www\\.)?dailymotion\\.com"
    ]
    
    struct ImportResult {
        let validURLs: [String]
        let invalidLines: [String]
        let totalLines: Int
        
        var successRate: Double {
            guard totalLines > 0 else { return 0 }
            return Double(validURLs.count) / Double(totalLines) * 100
        }
    }
    
    // Import URLs from a text file
    func importURLs(from fileURL: URL) throws -> ImportResult {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return parseContent(content)
    }
    
    // Import URLs from CSV file (assumes URLs are in first column or specified column)
    func importURLsFromCSV(from fileURL: URL, urlColumn: Int = 0) throws -> ImportResult {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return parseCSVContent(content, urlColumn: urlColumn)
    }
    
    // Parse plain text content for URLs
    private func parseContent(_ content: String) -> ImportResult {
        let lines = content.components(separatedBy: .newlines)
        var validURLs: [String] = []
        var invalidLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix("//") {
                continue
            }
            
            // Check if line contains a valid URL
            if let url = extractURL(from: trimmed) {
                validURLs.append(url)
            } else if !trimmed.isEmpty {
                invalidLines.append(trimmed)
            }
        }
        
        return ImportResult(
            validURLs: validURLs,
            invalidLines: invalidLines,
            totalLines: lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        )
    }
    
    // Parse CSV content for URLs
    private func parseCSVContent(_ content: String, urlColumn: Int) -> ImportResult {
        let lines = content.components(separatedBy: .newlines)
        var validURLs: [String] = []
        var invalidLines: [String] = []
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and potential header row
            if trimmed.isEmpty || (index == 0 && trimmed.lowercased().contains("url")) {
                continue
            }
            
            // Parse CSV line (simple parsing, handles basic comma separation)
            let columns = parseCSVLine(trimmed)
            
            if urlColumn < columns.count {
                let potentialURL = columns[urlColumn].trimmingCharacters(in: .whitespacesAndNewlines)
                if let url = extractURL(from: potentialURL) {
                    validURLs.append(url)
                } else if !potentialURL.isEmpty {
                    invalidLines.append(potentialURL)
                }
            } else if !trimmed.isEmpty {
                // Try to find URL in any column
                var foundURL = false
                for column in columns {
                    if let url = extractURL(from: column) {
                        validURLs.append(url)
                        foundURL = true
                        break
                    }
                }
                if !foundURL {
                    invalidLines.append(trimmed)
                }
            }
        }
        
        return ImportResult(
            validURLs: validURLs,
            invalidLines: invalidLines,
            totalLines: lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        )
    }
    
    // Simple CSV line parser that handles quoted values
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            } else {
                current.append(char)
            }
        }
        
        // Add the last field
        if !current.isEmpty {
            result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return result
    }
    
    // Extract URL from text (handles various formats)
    private func extractURL(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common markdown/markup formatting
        let cleanedText = trimmed
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "(", with: " ")
            .replacingOccurrences(of: ")", with: " ")
        
        // Try to find URL in the text
        let words = cleanedText.components(separatedBy: .whitespacesAndNewlines)
        for word in words {
            if isValidURL(word) {
                // Ensure it has a protocol
                if !word.hasPrefix("http://") && !word.hasPrefix("https://") {
                    return "https://\(word)"
                }
                return word
            }
        }
        
        // Check if the entire trimmed text is a URL
        if isValidURL(trimmed) {
            if !trimmed.hasPrefix("http://") && !trimmed.hasPrefix("https://") {
                return "https://\(trimmed)"
            }
            return trimmed
        }
        
        return nil
    }
    
    // Validate if string is a valid URL
    private func isValidURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        // Check against known patterns
        for pattern in urlPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil {
                return true
            }
        }
        
        // Additional check for URLs that might not have protocol
        if trimmed.contains(".") && !trimmed.contains(" ") {
            let components = trimmed.components(separatedBy: ".")
            if components.count >= 2 && !components[0].isEmpty && !components[1].isEmpty {
                // Looks like a domain
                return true
            }
        }
        
        return false
    }
    
    // Show file import dialog
    @MainActor
    func showImportDialog() async -> URL? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSOpenPanel()
                panel.title = "Import URLs from File"
                panel.message = "Select a text or CSV file containing URLs"
                panel.prompt = "Import"
                panel.allowedContentTypes = [.plainText, .commaSeparatedText]
                panel.allowsMultipleSelection = false
                
                panel.begin { response in
                    if response == .OK {
                        continuation.resume(returning: panel.url)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
}

// Import result dialog view
import SwiftUI

struct BatchImportResultView: View {
    let result: BatchImportService.ImportResult
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var showInvalidLines = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Import Results")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Divider()
            
            // Statistics
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("\(result.validURLs.count) valid URLs found", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Spacer()
                }
                
                if !result.invalidLines.isEmpty {
                    HStack {
                        Label("\(result.invalidLines.count) invalid lines", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Button(action: { showInvalidLines.toggle() }) {
                            Text(showInvalidLines ? "Hide" : "Show")
                                .font(.caption)
                        }
                        .buttonStyle(.link)
                        
                        Spacer()
                    }
                }
                
                HStack {
                    Text("Success rate:")
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", result.successRate))
                        .fontWeight(.medium)
                    Spacer()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Invalid lines (if any)
            if showInvalidLines && !result.invalidLines.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invalid lines:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(result.invalidLines.prefix(10), id: \.self) { line in
                                Text(line)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .lineLimit(1)
                            }
                            if result.invalidLines.count > 10 {
                                Text("... and \(result.invalidLines.count - 10) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
                }
            }
            
            // URL preview
            if !result.validURLs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("URLs to import:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(result.validURLs.prefix(5), id: \.self) { url in
                                Text(url)
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                    .lineLimit(1)
                            }
                            if result.validURLs.count > 5 {
                                Text("... and \(result.validURLs.count - 5) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 80)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(4)
                }
            }
            
            Divider()
            
            // Buttons
            HStack {
                Spacer()
                
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape)
                
                Button("Import \(result.validURLs.count) URLs") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(result.validURLs.isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 500)
    }
}