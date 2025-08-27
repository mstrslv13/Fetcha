import SwiftUI

struct FormatSelectionView: View {
    let videoInfo: VideoInfo
    @Binding var selectedFormat: VideoFormat?
    @State private var showAllFormats = false
    @State private var formatType = 0 // 0 = Video, 1 = Audio only
    
    private func matchesAudioPreference(format: VideoFormat, preference: String) -> Bool {
        return format.ext == preference || 
               (preference == "mp3" && format.acodec == "mp3") ||
               (preference == "m4a" && (format.ext == "m4a" || format.acodec == "aac")) ||
               (preference == "flac" && format.ext == "flac") ||
               (preference == "wav" && format.ext == "wav") ||
               (preference == "opus" && (format.ext == "opus" || format.acodec == "opus")) ||
               (preference == "vorbis" && (format.ext == "ogg" || format.acodec == "vorbis"))
    }
    
    private var filteredFormats: [VideoFormat] {
        guard let formats = videoInfo.formats else { return [] }
        
        if formatType == 0 {
            // Video formats (with video codec)
            return formats.filter { format in
                format.vcodec != nil && format.vcodec != "none"
            }.sorted { ($0.height ?? 0) > ($1.height ?? 0) }
        } else {
            // Audio only formats - prioritize user's preferred format
            let preferences = AppPreferences.shared
            let preferredAudioFormat = preferences.audioFormat
            
            let audioFormats = formats.filter { format in
                (format.vcodec == nil || format.vcodec == "none") && format.acodec != nil && format.acodec != "none"
            }
            
            // Sort with preferred format first, then by bitrate
            return audioFormats.sorted { format1, format2 in
                // Check if either format matches the preference
                let format1Matches = matchesAudioPreference(format: format1, preference: preferredAudioFormat)
                let format2Matches = matchesAudioPreference(format: format2, preference: preferredAudioFormat)
                
                if format1Matches && !format2Matches {
                    return true
                } else if !format1Matches && format2Matches {
                    return false
                } else {
                    // Both match or neither match, sort by bitrate
                    return (format1.abr ?? 0) > (format2.abr ?? 0)
                }
            }
        }
    }
    
    private var displayFormats: [VideoFormat] {
        showAllFormats ? filteredFormats : Array(filteredFormats.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Select Quality")
                    .font(.headline)
                
                Spacer()
                
                Picker("Format Type", selection: $formatType) {
                    Text("Video").tag(0)
                    Text("Audio Only").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            if !displayFormats.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: showAllFormats) {
                        VStack(spacing: 8) {
                            ForEach(displayFormats) { format in
                                FormatRow(
                                    format: format,
                                    isSelected: selectedFormat?.id == format.id,
                                    isAudioOnly: formatType == 1
                                ) {
                                    selectedFormat = format
                                }
                            }
                        }
                    }
                    .frame(maxHeight: showAllFormats ? 300 : nil)
                }
                
                if filteredFormats.count > 5 {
                    Button(showAllFormats ? "Show Less" : "Show More Formats") {
                        withAnimation {
                            showAllFormats.toggle()
                        }
                    }
                    .buttonStyle(.link)
                    .padding(.top, 5)
                }
            } else {
                Text("No \(formatType == 0 ? "video" : "audio") formats available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .onAppear {
            selectedFormat = videoInfo.bestFormat
        }
        .onChange(of: formatType) { oldValue, newValue in
            // Reset selection when switching format types
            selectedFormat = nil
        }
    }
}

struct FormatRow: View {
    let format: VideoFormat
    let isSelected: Bool
    let isAudioOnly: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    if isAudioOnly {
                        // Audio format display
                        Text(format.audioQualityLabel)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        
                        HStack(spacing: 6) {
                            if let abr = format.abr {
                                Label("\(Int(abr))kbps", systemImage: "waveform")
                                    .font(.caption)
                            }
                            if let acodec = format.acodec, acodec != "none" {
                                Text(acodec.uppercased())
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        .foregroundColor(.secondary)
                    } else {
                        // Video format display
                        Text(format.qualityLabel)
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                        
                        Text(format.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let filesize = format.filesize_approx ?? format.filesize {
                    Text(formatBytes(filesize))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

extension VideoFormat {
    var audioQualityLabel: String {
        if let abr = abr {
            return "\(Int(abr))kbps Audio"
        } else if let format_note = format_note {
            return format_note
        } else {
            return "Audio"
        }
    }
}