import SwiftUI
import Foundation

enum FormatType: String, CaseIterable {
    case bestVideo = "Best Video"
    case mp4 = "MP4 Video"
    case webm = "WebM Video"
    case mkv = "MKV Video"
    case bestAudio = "Best Audio"
    case mp3 = "MP3 Audio"
    case m4a = "M4A Audio"
    case opus = "Opus Audio"
    
    var isAudio: Bool {
        switch self {
        case .bestAudio, .mp3, .m4a, .opus:
            return true
        default:
            return false
        }
    }
    
    var fileExtension: String? {
        switch self {
        case .mp4: return "mp4"
        case .webm: return "webm"
        case .mkv: return "mkv"
        case .mp3: return "mp3"
        case .m4a: return "m4a"
        case .opus: return "opus"
        default: return nil
        }
    }
    
    func getBestFormat(from formats: [VideoFormat]) -> VideoFormat? {
        let filteredFormats: [VideoFormat]
        
        switch self {
        case .bestVideo:
            // Get best quality video format
            filteredFormats = formats.filter { 
                $0.vcodec != nil && $0.vcodec != "none" 
            }.sorted { ($0.height ?? 0) > ($1.height ?? 0) }
            
        case .mp4:
            // Get best MP4 video
            filteredFormats = formats.filter { 
                $0.ext == "mp4" && $0.vcodec != nil && $0.vcodec != "none"
            }.sorted { ($0.height ?? 0) > ($1.height ?? 0) }
            
        case .webm:
            // Get best WebM video
            filteredFormats = formats.filter { 
                $0.ext == "webm" && $0.vcodec != nil && $0.vcodec != "none"
            }.sorted { ($0.height ?? 0) > ($1.height ?? 0) }
            
        case .mkv:
            // Get best MKV video
            filteredFormats = formats.filter { 
                $0.ext == "mkv" && $0.vcodec != nil && $0.vcodec != "none"
            }.sorted { ($0.height ?? 0) > ($1.height ?? 0) }
            
        case .bestAudio:
            // Get best quality audio format based on user preference
            let preferences = AppPreferences.shared
            let preferredAudioFormat = preferences.audioFormat
            
            // First try to find the preferred format
            let preferredFormats = formats.filter { format in
                format.acodec != nil && format.acodec != "none" && 
                (format.vcodec == nil || format.vcodec == "none") &&
                (format.ext == preferredAudioFormat || 
                 (preferredAudioFormat == "mp3" && format.acodec == "mp3") ||
                 (preferredAudioFormat == "m4a" && (format.ext == "m4a" || format.acodec == "aac")) ||
                 (preferredAudioFormat == "flac" && format.ext == "flac") ||
                 (preferredAudioFormat == "wav" && format.ext == "wav") ||
                 (preferredAudioFormat == "opus" && (format.ext == "opus" || format.acodec == "opus")) ||
                 (preferredAudioFormat == "vorbis" && (format.ext == "ogg" || format.acodec == "vorbis")))
            }.sorted { ($0.abr ?? 0) > ($1.abr ?? 0) }
            
            // If preferred format not found, get any audio format
            if preferredFormats.isEmpty {
                filteredFormats = formats.filter { 
                    $0.acodec != nil && $0.acodec != "none" && ($0.vcodec == nil || $0.vcodec == "none")
                }.sorted { ($0.abr ?? 0) > ($1.abr ?? 0) }
            } else {
                filteredFormats = preferredFormats
            }
            
        case .mp3:
            // Get best MP3 audio
            filteredFormats = formats.filter { 
                ($0.ext == "mp3" || $0.acodec == "mp3") && ($0.vcodec == nil || $0.vcodec == "none")
            }.sorted { ($0.abr ?? 0) > ($1.abr ?? 0) }
            
        case .m4a:
            // Get best M4A audio
            filteredFormats = formats.filter { 
                ($0.ext == "m4a" || $0.acodec == "aac") && ($0.vcodec == nil || $0.vcodec == "none")
            }.sorted { ($0.abr ?? 0) > ($1.abr ?? 0) }
            
        case .opus:
            // Get best Opus audio
            filteredFormats = formats.filter { 
                ($0.ext == "opus" || $0.acodec == "opus") && ($0.vcodec == nil || $0.vcodec == "none")
            }.sorted { ($0.abr ?? 0) > ($1.abr ?? 0) }
        }
        
        // If specific format not found, fall back
        if filteredFormats.isEmpty {
            if isAudio {
                // Fall back to any audio format
                return formats.filter { 
                    $0.acodec != nil && $0.acodec != "none" && ($0.vcodec == nil || $0.vcodec == "none")
                }.sorted { ($0.abr ?? 0) > ($1.abr ?? 0) }.first
            } else {
                // Fall back to any video format
                return formats.filter { 
                    $0.vcodec != nil && $0.vcodec != "none"
                }.sorted { ($0.height ?? 0) > ($1.height ?? 0) }.first
            }
        }
        
        return filteredFormats.first
    }
}

struct FormatTypeSelector: View {
    @Binding var selectedType: FormatType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Default Format Type")
                .font(.headline)
            
            VStack(spacing: 8) {
                Text("Video Formats")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach([FormatType.bestVideo, .mp4, .webm, .mkv], id: \.self) { type in
                    HStack {
                        Image(systemName: selectedType == type ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedType == type ? .blue : .secondary)
                        Text(type.rawValue)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedType = type
                    }
                    .padding(.vertical, 4)
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                Text("Audio Formats")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach([FormatType.bestAudio, .mp3, .m4a, .opus], id: \.self) { type in
                    HStack {
                        Image(systemName: selectedType == type ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedType == type ? .blue : .secondary)
                        Text(type.rawValue)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedType = type
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Text("Videos will be downloaded in the selected format when available, otherwise the next best format will be used.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(NSColor.tertiaryLabelColor).opacity(0.05))
        .cornerRadius(10)
    }
}