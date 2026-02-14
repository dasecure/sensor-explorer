import SwiftUI
import LocalAuthentication
import ARKit

struct BiometricView: View {
    @StateObject private var biometricManager = BiometricManager()
    @State private var showFaceTracking = false
    
    var body: some View {
        NavigationStack {
            List {
                // Biometric Type Section
                Section("Biometric Authentication") {
                    HStack {
                        Image(systemName: biometricManager.biometricIcon)
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(biometricManager.biometricType)
                                .font(.headline)
                            Text(biometricManager.biometricDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Button("Test Authentication") {
                        biometricManager.authenticate()
                    }
                    
                    if let result = biometricManager.authResult {
                        HStack {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result ? .green : .red)
                            Text(result ? "Authentication Successful" : "Authentication Failed")
                        }
                    }
                }
                
                // TrueDepth Camera Section
                Section("TrueDepth Camera (Face ID)") {
                    StatusRow(label: "TrueDepth Available", available: biometricManager.isTrueDepthAvailable)
                    StatusRow(label: "Face Tracking", available: ARFaceTrackingConfiguration.isSupported)
                    
                    if ARFaceTrackingConfiguration.isSupported {
                        NavigationLink("Face Tracking Demo") {
                            FaceTrackingView()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TrueDepth Capabilities:")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 4) {
                            CapabilityRow(text: "Face ID Authentication")
                            CapabilityRow(text: "Face Tracking (52 blend shapes)")
                            CapabilityRow(text: "Depth Map Generation")
                            CapabilityRow(text: "Animoji & Memoji")
                            CapabilityRow(text: "Portrait Mode (Front)")
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Biometric Status
                Section("Status") {
                    HStack {
                        Text("Biometric Enrolled")
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: biometricManager.isBiometricEnrolled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(biometricManager.isBiometricEnrolled ? .green : .red)
                    }
                    
                    if let error = biometricManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Biometrics")
        }
    }
}

// MARK: - Biometric Manager

class BiometricManager: ObservableObject {
    private let context = LAContext()
    
    @Published var authResult: Bool?
    @Published var errorMessage: String?
    
    var biometricType: String {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "None Available"
        }
        
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "None"
        @unknown default: return "Unknown"
        }
    }
    
    var biometricIcon: String {
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "questionmark.circle"
        }
    }
    
    var biometricDescription: String {
        switch context.biometryType {
        case .faceID: return "Uses TrueDepth camera for 3D face mapping"
        case .touchID: return "Uses capacitive fingerprint sensor"
        case .opticID: return "Uses iris scanning technology"
        default: return "No biometric authentication available"
        }
    }
    
    var isTrueDepthAvailable: Bool {
        context.biometryType == .faceID
    }
    
    var isBiometricEnrolled: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func authenticate() {
        let context = LAContext() // Fresh context for each auth
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = error?.localizedDescription ?? "Biometrics not available"
            authResult = false
            return
        }
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Authenticate to test biometric sensor"
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.authResult = success
                self?.errorMessage = error?.localizedDescription
            }
        }
    }
}

// MARK: - Face Tracking View

struct FaceTrackingView: View {
    @StateObject private var faceTracker = FaceTracker()
    
    var body: some View {
        VStack(spacing: 20) {
            // Face mesh visualization placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                
                if faceTracker.isFaceDetected {
                    VStack {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("Face Detected!")
                            .foregroundColor(.green)
                    }
                } else {
                    VStack {
                        Image(systemName: "face.dashed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Point camera at face")
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(height: 300)
            
            // Expression data
            if faceTracker.isFaceDetected {
                List {
                    Section("Face Expressions") {
                        ExpressionRow(label: "Smile Left", value: faceTracker.smileLeft)
                        ExpressionRow(label: "Smile Right", value: faceTracker.smileRight)
                        ExpressionRow(label: "Blink Left", value: faceTracker.blinkLeft)
                        ExpressionRow(label: "Blink Right", value: faceTracker.blinkRight)
                        ExpressionRow(label: "Brow Up Left", value: faceTracker.browUpLeft)
                        ExpressionRow(label: "Brow Up Right", value: faceTracker.browUpRight)
                        ExpressionRow(label: "Jaw Open", value: faceTracker.jawOpen)
                    }
                }
            }
            
            Spacer()
        }
        .navigationTitle("Face Tracking")
        .onAppear {
            faceTracker.startTracking()
        }
        .onDisappear {
            faceTracker.stopTracking()
        }
    }
}

// MARK: - Face Tracker

class FaceTracker: NSObject, ObservableObject, ARSessionDelegate {
    private var session: ARSession?
    
    @Published var isFaceDetected = false
    @Published var smileLeft: Float = 0
    @Published var smileRight: Float = 0
    @Published var blinkLeft: Float = 0
    @Published var blinkRight: Float = 0
    @Published var browUpLeft: Float = 0
    @Published var browUpRight: Float = 0
    @Published var jawOpen: Float = 0
    
    func startTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        session = ARSession()
        session?.delegate = self
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        session?.run(configuration)
    }
    
    func stopTracking() {
        session?.pause()
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else {
            DispatchQueue.main.async {
                self.isFaceDetected = false
            }
            return
        }
        
        let blendShapes = faceAnchor.blendShapes
        
        DispatchQueue.main.async {
            self.isFaceDetected = true
            self.smileLeft = blendShapes[.mouthSmileLeft]?.floatValue ?? 0
            self.smileRight = blendShapes[.mouthSmileRight]?.floatValue ?? 0
            self.blinkLeft = blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
            self.blinkRight = blendShapes[.eyeBlinkRight]?.floatValue ?? 0
            self.browUpLeft = blendShapes[.browOuterUpLeft]?.floatValue ?? 0
            self.browUpRight = blendShapes[.browOuterUpRight]?.floatValue ?? 0
            self.jawOpen = blendShapes[.jawOpen]?.floatValue ?? 0
        }
    }
}

// MARK: - Helper Views

struct CapabilityRow: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark")
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
    }
}

struct ExpressionRow: View {
    let label: String
    let value: Float
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            ProgressView(value: Double(value), total: 1.0)
                .frame(width: 100)
            Text(String(format: "%.0f%%", value * 100))
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
    }
}

#Preview {
    BiometricView()
}
