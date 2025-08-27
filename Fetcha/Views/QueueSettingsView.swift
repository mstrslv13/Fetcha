import SwiftUI
import Combine

struct QueueSettingsView: View {
    @ObservedObject var queue: DownloadQueue
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                Text("Queue Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
            
            Divider()
            
            // Parallel Downloads Setting
            VStack(alignment: .leading, spacing: 8) {
                Text("Parallel Downloads")
                    .font(.headline)
                
                HStack {
                    Text("Max concurrent downloads:")
                    Picker("", selection: $queue.maxConcurrentDownloads) {
                        ForEach(1...10, id: \.self) { num in
                            Text("\(num)").tag(num)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 80)
                    
                    Text("downloads")
                        .foregroundColor(.secondary)
                }
                
                Text("Higher values download multiple videos simultaneously but may affect performance")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.tertiaryLabelColor).opacity(0.05))
            .cornerRadius(10)
            
            // Consistent Format Setting
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Consistent Format")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $queue.useConsistentFormat)
                        .toggleStyle(.switch)
                        .onChange(of: queue.useConsistentFormat) { oldValue, newValue in
                            UserDefaults.standard.set(newValue, forKey: "useConsistentFormat")
                        }
                }
                
                if queue.useConsistentFormat {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All queued videos will use this format type:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        FormatTypeSelector(selectedType: Binding(
                            get: { queue.consistentFormatType },
                            set: { newType in
                                queue.consistentFormatType = newType
                                queue.setConsistentFormatType(newType)
                            }
                        ))
                    }
                } else {
                    Text("Each video will use individually selected format")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.tertiaryLabelColor).opacity(0.05))
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .frame(width: 550, height: 700)
    }
}