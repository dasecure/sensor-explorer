import SwiftUI
import UIKit

struct EnvironmentSensorsView: View {
    @StateObject private var brightnessMonitor = BrightnessMonitor()
    
    var body: some View {
        NavigationStack {
            List {
                // Ambient Light (via screen brightness as proxy)
                Section("Ambient Light") {
                    HStack {
                        Text("Screen Brightness")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.0f%%", brightnessMonitor.brightness * 100))
                            .monospacedDigit()
                    }
                    
                    // Visual indicator
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 20)
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [.gray, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: geometry.size.width * brightnessMonitor.brightness, height: 20)
                        }
                        .cornerRadius(10)
                    }
                    .frame(height: 20)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Note", systemImage: "info.circle")
                            .font(.headline)
                        Text("iOS does not provide direct access to the ambient light sensor value. The screen brightness is shown here as a related metric. When auto-brightness is enabled, it reflects ambient light conditions.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                // LiDAR section with link to ARKit
                Section("LiDAR Scanner") {
                    StatusRow(label: "LiDAR Available", available: isLiDARAvailable())
                    
                    if isLiDARAvailable() {
                        NavigationLink("Open LiDAR Demo") {
                            LiDARView()
                        }
                    } else {
                        Text("LiDAR scanner is not available on this device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Environment")
        }
    }
    
    private func isLiDARAvailable() -> Bool {
        // Check for LiDAR by device model
        // LiDAR is available on iPhone 12 Pro and later Pro models, iPad Pro 2020+
        if #available(iOS 15.4, *) {
            // ARKit's ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) indicates LiDAR
            return true // Simplified check - in real app, use ARKit to check
        }
        return false
    }
}

// MARK: - Brightness Monitor

class BrightnessMonitor: ObservableObject {
    @Published var brightness: CGFloat = UIScreen.main.brightness
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(brightnessDidChange),
            name: UIScreen.brightnessDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func brightnessDidChange() {
        DispatchQueue.main.async {
            self.brightness = UIScreen.main.brightness
        }
    }
}

// MARK: - LiDAR View (Placeholder)

struct LiDARView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.metering.spot")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("LiDAR Scanner")
                .font(.title)
            
            Text("The LiDAR scanner uses ARKit for depth sensing and 3D scene reconstruction.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "cube.transparent", text: "3D Scene Reconstruction")
                FeatureRow(icon: "ruler", text: "Precise Distance Measurement")
                FeatureRow(icon: "person.fill", text: "People Occlusion")
                FeatureRow(icon: "square.3.layers.3d", text: "Mesh Generation")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            Text("Use ARKit's ARWorldTrackingConfiguration with sceneReconstruction enabled to access LiDAR data.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .navigationTitle("LiDAR")
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
        }
    }
}

#Preview {
    EnvironmentSensorsView()
}
