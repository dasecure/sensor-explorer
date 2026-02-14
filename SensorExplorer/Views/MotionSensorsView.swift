import SwiftUI
import CoreMotion

struct MotionSensorsView: View {
    @StateObject private var motionManager = MotionManager()
    
    var body: some View {
        NavigationStack {
            List {
                // Accelerometer Section
                Section("Accelerometer") {
                    SensorRow(label: "X", value: motionManager.accelerometerData.x, unit: "g")
                    SensorRow(label: "Y", value: motionManager.accelerometerData.y, unit: "g")
                    SensorRow(label: "Z", value: motionManager.accelerometerData.z, unit: "g")
                }
                
                // Gyroscope Section
                Section("Gyroscope") {
                    SensorRow(label: "X", value: motionManager.gyroData.x, unit: "rad/s")
                    SensorRow(label: "Y", value: motionManager.gyroData.y, unit: "rad/s")
                    SensorRow(label: "Z", value: motionManager.gyroData.z, unit: "rad/s")
                }
                
                // Magnetometer Section
                Section("Magnetometer") {
                    SensorRow(label: "X", value: motionManager.magnetometerData.x, unit: "µT")
                    SensorRow(label: "Y", value: motionManager.magnetometerData.y, unit: "µT")
                    SensorRow(label: "Z", value: motionManager.magnetometerData.z, unit: "µT")
                }
                
                // Device Motion (Attitude)
                Section("Device Attitude") {
                    SensorRow(label: "Pitch", value: motionManager.attitude.pitch * 180 / .pi, unit: "°")
                    SensorRow(label: "Roll", value: motionManager.attitude.roll * 180 / .pi, unit: "°")
                    SensorRow(label: "Yaw", value: motionManager.attitude.yaw * 180 / .pi, unit: "°")
                }
                
                // Barometer Section
                Section("Barometer") {
                    SensorRow(label: "Pressure", value: motionManager.pressure, unit: "kPa")
                    SensorRow(label: "Relative Altitude", value: motionManager.relativeAltitude, unit: "m")
                }
                
                // Status Section
                Section("Status") {
                    StatusRow(label: "Accelerometer", available: motionManager.isAccelerometerAvailable)
                    StatusRow(label: "Gyroscope", available: motionManager.isGyroAvailable)
                    StatusRow(label: "Magnetometer", available: motionManager.isMagnetometerAvailable)
                    StatusRow(label: "Device Motion", available: motionManager.isDeviceMotionAvailable)
                    StatusRow(label: "Barometer", available: motionManager.isBarometerAvailable)
                }
            }
            .navigationTitle("Motion Sensors")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(motionManager.isRunning ? "Stop" : "Start") {
                        if motionManager.isRunning {
                            motionManager.stopUpdates()
                        } else {
                            motionManager.startUpdates()
                        }
                    }
                }
            }
        }
        .onAppear {
            motionManager.startUpdates()
        }
        .onDisappear {
            motionManager.stopUpdates()
        }
    }
}

// MARK: - Motion Manager

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()
    
    @Published var accelerometerData: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @Published var gyroData: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @Published var magnetometerData: (x: Double, y: Double, z: Double) = (0, 0, 0)
    @Published var attitude: (pitch: Double, roll: Double, yaw: Double) = (0, 0, 0)
    @Published var pressure: Double = 0
    @Published var relativeAltitude: Double = 0
    @Published var isRunning = false
    
    var isAccelerometerAvailable: Bool { motionManager.isAccelerometerAvailable }
    var isGyroAvailable: Bool { motionManager.isGyroscopeAvailable }
    var isMagnetometerAvailable: Bool { motionManager.isMagnetometerAvailable }
    var isDeviceMotionAvailable: Bool { motionManager.isDeviceMotionAvailable }
    var isBarometerAvailable: Bool { CMAltimeter.isRelativeAltitudeAvailable() }
    
    func startUpdates() {
        isRunning = true
        let interval = 1.0 / 30.0 // 30 Hz
        
        // Accelerometer
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = interval
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                self?.accelerometerData = (data.acceleration.x, data.acceleration.y, data.acceleration.z)
            }
        }
        
        // Gyroscope
        if motionManager.isGyroscopeAvailable {
            motionManager.gyroUpdateInterval = interval
            motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                self?.gyroData = (data.rotationRate.x, data.rotationRate.y, data.rotationRate.z)
            }
        }
        
        // Magnetometer
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = interval
            motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                self?.magnetometerData = (data.magneticField.x, data.magneticField.y, data.magneticField.z)
            }
        }
        
        // Device Motion (includes attitude)
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = interval
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                self?.attitude = (data.attitude.pitch, data.attitude.roll, data.attitude.yaw)
            }
        }
        
        // Barometer
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
                guard let data = data else { return }
                self?.pressure = data.pressure.doubleValue
                self?.relativeAltitude = data.relativeAltitude.doubleValue
            }
        }
    }
    
    func stopUpdates() {
        isRunning = false
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        altimeter.stopRelativeAltitudeUpdates()
    }
}

// MARK: - Helper Views

struct SensorRow: View {
    let label: String
    let value: Double
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: "%.4f", value))
                .monospacedDigit()
            Text(unit)
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}

struct StatusRow: View {
    let label: String
    let available: Bool
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(available ? .green : .red)
        }
    }
}

#Preview {
    MotionSensorsView()
}
