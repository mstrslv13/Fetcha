import SwiftUI

struct DownloadProgressView: View {
    @ObservedObject var task: DownloadTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.videoInfo.title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(task.state.description)
                        .font(.caption)
                        .foregroundColor(stateColor)
                }
                
                Spacer()
                
                if task.state.isActive {
                    Button(action: {
                        task.cancel()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if task.state.isActive {
                ProgressView(value: task.progress, total: 100)
                    .progressViewStyle(.linear)
                
                HStack {
                    if !task.speed.isEmpty {
                        Label(task.speed, systemImage: "speedometer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !task.eta.isEmpty {
                        Label("ETA: \(task.eta)", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(Int(task.progress))%")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var stateColor: Color {
        switch task.state {
        case .completed:
            return Color.green
        case .failed:
            return Color.red
        case .cancelled:
            return Color.orange
        case .downloading, .preparing, .merging:
            return .accentColor
        default:
            return .secondary
        }
    }
}