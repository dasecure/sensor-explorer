import SwiftUI
import CoreNFC
import NearbyInteraction
import UIKit

struct ProximityView: View {
    @StateObject private var nfcManager = NFCManager()
    @StateObject private var uwbManager = UWBManager()
    @StateObject private var proximityMonitor = ProximityMonitor()
    
    var body: some View {
        NavigationStack {
            List {
                // Proximity Sensor Section
                Section("Proximity Sensor") {
                    HStack {
                        Image(systemName: proximityMonitor.isNear ? "hand.raised.fill" : "hand.raised")
                            .font(.largeTitle)
                            .foregroundColor(proximityMonitor.isNear ? .red : .green)
                        VStack(alignment: .leading) {
                            Text(proximityMonitor.isNear ? "Object Detected" : "Clear")
                                .font(.headline)
                            Text("Used for screen dimming during calls")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Toggle("Monitor Proximity", isOn: $proximityMonitor.isMonitoring)
                }
                
                // NFC Section
                Section("NFC Reader") {
                    StatusRow(label: "NFC Available", available: NFCNDEFReaderSession.readingAvailable)
                    
                    if NFCNDEFReaderSession.readingAvailable {
                        Button("Scan NFC Tag") {
                            nfcManager.beginScanning()
                        }
                        .disabled(nfcManager.isScanning)
                        
                        if nfcManager.isScanning {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Scanning...")
                            }
                        }
                        
                        if let message = nfcManager.lastMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Last Scanned:")
                                    .font(.headline)
                                Text(message)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if let error = nfcManager.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else {
                        Text("NFC is not available on this device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NFC Capabilities:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("• NDEF Tag Reading")
                        Text("• Tag Writing (supported tags)")
                        Text("• ISO 7816 Smart Cards")
                        Text("• ISO 15693 Tags")
                        Text("• Apple Pay")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
                }
                
                // Ultra Wideband Section
                Section("Ultra Wideband (UWB)") {
                    StatusRow(label: "UWB Available", available: uwbManager.isUWBAvailable)
                    
                    if uwbManager.isUWBAvailable {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("UWB Capabilities:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Image(systemName: "ruler")
                                    .foregroundColor(.blue)
                                Text("Precise distance measurement (±10cm)")
                            }
                            
                            HStack {
                                Image(systemName: "arrow.up.right.circle")
                                    .foregroundColor(.blue)
                                Text("Directional awareness")
                            }
                            
                            HStack {
                                Image(systemName: "airtag")
                                    .foregroundColor(.blue)
                                Text("AirTag & Find My integration")
                            }
                            
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundColor(.blue)
                                Text("Car key functionality")
                            }
                            
                            HStack {
                                Image(systemName: "homepodmini.fill")
                                    .foregroundColor(.blue)
                                Text("Handoff with HomePod")
                            }
                        }
                        .font(.caption)
                        .padding(.vertical, 4)
                        
                        NavigationLink("UWB Session Demo") {
                            UWBSessionView(uwbManager: uwbManager)
                        }
                    } else {
                        Text("UWB is not available on this device (iPhone 11 and later)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Device Info
                Section("Device Sensors Summary") {
                    SensorSummaryRow(icon: "gyroscope", name: "Gyroscope", available: true)
                    SensorSummaryRow(icon: "move.3d", name: "Accelerometer", available: true)
                    SensorSummaryRow(icon: "barometer", name: "Barometer", available: true)
                    SensorSummaryRow(icon: "location.fill", name: "GPS", available: true)
                    SensorSummaryRow(icon: "faceid", name: "Face ID", available: true)
                    SensorSummaryRow(icon: "camera.metering.spot", name: "LiDAR", available: true)
                    SensorSummaryRow(icon: "wave.3.forward", name: "NFC", available: NFCNDEFReaderSession.readingAvailable)
                    SensorSummaryRow(icon: "antenna.radiowaves.left.and.right", name: "UWB", available: uwbManager.isUWBAvailable)
                }
            }
            .navigationTitle("Proximity")
        }
        .onAppear {
            proximityMonitor.startMonitoring()
        }
        .onDisappear {
            proximityMonitor.stopMonitoring()
        }
    }
}

// MARK: - NFC Manager

class NFCManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var isScanning = false
    @Published var lastMessage: String?
    @Published var errorMessage: String?
    
    private var session: NFCNDEFReaderSession?
    
    func beginScanning() {
        guard NFCNDEFReaderSession.readingAvailable else {
            errorMessage = "NFC not available"
            return
        }
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your iPhone near an NFC tag"
        session?.begin()
        isScanning = true
        errorMessage = nil
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        var result = ""
        
        for message in messages {
            for record in message.records {
                if let payload = String(data: record.payload, encoding: .utf8) {
                    result += payload + "\n"
                }
                result += "Type: \(record.typeNameFormat)\n"
            }
        }
        
        DispatchQueue.main.async {
            self.lastMessage = result.isEmpty ? "Empty tag" : result
            self.isScanning = false
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
            if let nfcError = error as? NFCReaderError,
               nfcError.code != .readerSessionInvalidationErrorUserCanceled {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - UWB Manager

class UWBManager: NSObject, ObservableObject, NISessionDelegate {
    @Published var isUWBAvailable = false
    @Published var nearbyObjects: [NINearbyObject] = []
    @Published var sessionState: String = "Inactive"
    
    private var session: NISession?
    
    override init() {
        super.init()
        isUWBAvailable = NISession.isSupported
    }
    
    func startSession(with token: NIDiscoveryToken) {
        session = NISession()
        session?.delegate = self
        
        let config = NINearbyPeerConfiguration(peerToken: token)
        session?.run(config)
        sessionState = "Running"
    }
    
    func stopSession() {
        session?.invalidate()
        session = nil
        sessionState = "Inactive"
        nearbyObjects = []
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        DispatchQueue.main.async {
            self.nearbyObjects = nearbyObjects
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        DispatchQueue.main.async {
            self.nearbyObjects.removeAll { obj in
                nearbyObjects.contains { $0.discoveryToken == obj.discoveryToken }
            }
        }
    }
    
    func sessionWasSuspended(_ session: NISession) {
        DispatchQueue.main.async {
            self.sessionState = "Suspended"
        }
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        DispatchQueue.main.async {
            self.sessionState = "Running"
        }
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        DispatchQueue.main.async {
            self.sessionState = "Invalid: \(error.localizedDescription)"
        }
    }
}

// MARK: - Proximity Monitor

class ProximityMonitor: ObservableObject {
    @Published var isNear = false
    @Published var isMonitoring = false {
        didSet {
            if isMonitoring {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }
    
    func startMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(proximityChanged),
            name: UIDevice.proximityStateDidChangeNotification,
            object: nil
        )
        
        isMonitoring = true
    }
    
    func stopMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self)
        isMonitoring = false
        isNear = false
    }
    
    @objc private func proximityChanged() {
        DispatchQueue.main.async {
            self.isNear = UIDevice.current.proximityState
        }
    }
}

// MARK: - UWB Session View

struct UWBSessionView: View {
    @ObservedObject var uwbManager: UWBManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Ultra Wideband Session")
                .font(.title2)
            
            Text("Status: \(uwbManager.sessionState)")
                .foregroundColor(.secondary)
            
            if uwbManager.nearbyObjects.isEmpty {
                Text("No nearby UWB devices detected")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(uwbManager.nearbyObjects, id: \.discoveryToken) { object in
                    VStack(alignment: .leading) {
                        if let distance = object.distance {
                            Text("Distance: \(String(format: "%.2f", distance)) m")
                        }
                        if let direction = object.direction {
                            Text("Direction: x=\(String(format: "%.2f", direction.x)), y=\(String(format: "%.2f", direction.y)), z=\(String(format: "%.2f", direction.z))")
                                .font(.caption)
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("To test UWB, you need another device with UWB capability.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("UWB is used by AirTags, CarKey, and peer-to-peer ranging.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding()
        }
        .padding()
        .navigationTitle("UWB Session")
    }
}

// MARK: - Helper Views

struct SensorSummaryRow: View {
    let icon: String
    let name: String
    let available: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(name)
            Spacer()
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(available ? .green : .red)
        }
    }
}

#Preview {
    ProximityView()
}
