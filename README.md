# Sensor Explorer

A comprehensive iOS app demonstrating all major iPhone sensors and capabilities.

## Sensors Covered

### Motion Sensors
- **Accelerometer** - 3-axis linear acceleration (X, Y, Z in g-force)
- **Gyroscope** - 3-axis rotation rate (X, Y, Z in rad/s)
- **Magnetometer** - 3-axis magnetic field (X, Y, Z in µT)
- **Barometer** - Atmospheric pressure (kPa) and relative altitude (m)
- **Device Motion** - Fused sensor data with attitude (pitch, roll, yaw)

### Location Sensors
- **GPS** - Latitude, longitude, altitude with accuracy
- **Compass** - Magnetic and true heading
- **Speed & Course** - Movement tracking
- **Indoor Positioning** - Floor level detection

### Biometric & TrueDepth
- **Face ID** - Biometric authentication
- **TrueDepth Camera** - 3D face mapping, depth sensing
- **ARKit Face Tracking** - 52 blend shapes for facial expressions

### Proximity & Wireless
- **Proximity Sensor** - Object detection (near/far)
- **NFC Reader** - NDEF tag scanning
- **Ultra Wideband (UWB)** - Precise distance and direction

### Environment
- **Ambient Light** - Screen brightness (proxy for light sensor)
- **LiDAR Scanner** - 3D scene reconstruction (ARKit)

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Physical device for most sensors (simulator has limited support)

## Device Compatibility

| Sensor | iPhone Models |
|--------|--------------|
| Accelerometer | All |
| Gyroscope | All |
| Barometer | iPhone 6+ |
| Face ID | iPhone X+ (notch/Dynamic Island) |
| LiDAR | iPhone 12 Pro+, iPad Pro 2020+ |
| NFC | iPhone 7+ |
| UWB | iPhone 11+ |

## Setup in Xcode

1. Open Xcode and create a new iOS App project
2. Copy all Swift files into your project
3. Add required capabilities:
   - **Signing & Capabilities** → **+ Capability**
   - Add: Near Field Communication Tag Reading
   - Add: Nearby Interaction (for UWB)

4. Add entitlements file with:
```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>NDEF</string>
    <string>TAG</string>
</array>
<key>com.apple.developer.nearby-interaction</key>
<true/>
```

5. Update Info.plist with privacy descriptions (included in project)

6. Build and run on a physical device

## Project Structure

```
SensorExplorer/
├── SensorExplorerApp.swift       # App entry point
├── ContentView.swift             # Tab-based navigation
├── Info.plist                    # Privacy permissions
└── Views/
    ├── MotionSensorsView.swift   # Accelerometer, Gyro, Barometer
    ├── EnvironmentSensorsView.swift  # Light, LiDAR
    ├── LocationView.swift        # GPS, Compass
    ├── BiometricView.swift       # Face ID, Face Tracking
    └── ProximityView.swift       # NFC, UWB, Proximity
```

## Frameworks Used

- **CoreMotion** - Accelerometer, Gyroscope, Magnetometer, Barometer
- **CoreLocation** - GPS, Compass, Indoor Positioning
- **LocalAuthentication** - Face ID / Touch ID
- **ARKit** - Face Tracking, LiDAR, Depth
- **CoreNFC** - NFC Tag Reading
- **NearbyInteraction** - Ultra Wideband
- **MapKit** - Map display

## Notes

### Ambient Light Sensor
iOS doesn't provide direct access to the ambient light sensor value. The app shows screen brightness as a proxy when auto-brightness is enabled.

### Proximity Sensor
Only triggers during active monitoring. Used by iOS to turn off screen during calls.

### LiDAR
Requires ARKit session with scene reconstruction enabled. Available on Pro models only.

### UWB
Requires another UWB device to demonstrate ranging. Used by AirTags, CarKey, etc.

## License

MIT License - Feel free to use and modify.
