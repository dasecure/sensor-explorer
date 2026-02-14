import SwiftUI
import CoreLocation
import MapKit

struct LocationView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationStack {
            List {
                // Map Section
                Section {
                    Map(coordinateRegion: $locationManager.region, showsUserLocation: true)
                        .frame(height: 200)
                        .cornerRadius(12)
                }
                
                // Coordinates Section
                Section("Coordinates") {
                    CoordinateRow(label: "Latitude", value: locationManager.location?.coordinate.latitude ?? 0, format: "%.6f°")
                    CoordinateRow(label: "Longitude", value: locationManager.location?.coordinate.longitude ?? 0, format: "%.6f°")
                    CoordinateRow(label: "Altitude", value: locationManager.location?.altitude ?? 0, format: "%.1f m")
                }
                
                // Accuracy Section
                Section("Accuracy") {
                    CoordinateRow(label: "Horizontal", value: locationManager.location?.horizontalAccuracy ?? -1, format: "%.1f m")
                    CoordinateRow(label: "Vertical", value: locationManager.location?.verticalAccuracy ?? -1, format: "%.1f m")
                }
                
                // Speed & Course Section
                Section("Movement") {
                    CoordinateRow(label: "Speed", value: max(0, locationManager.location?.speed ?? 0) * 3.6, format: "%.1f km/h")
                    CoordinateRow(label: "Course", value: locationManager.location?.course ?? -1, format: "%.1f°")
                }
                
                // Heading (Compass)
                Section("Compass") {
                    if let heading = locationManager.heading {
                        CoordinateRow(label: "Magnetic Heading", value: heading.magneticHeading, format: "%.1f°")
                        CoordinateRow(label: "True Heading", value: heading.trueHeading, format: "%.1f°")
                        CoordinateRow(label: "Accuracy", value: heading.headingAccuracy, format: "±%.1f°")
                        
                        // Compass visualization
                        CompassView(heading: heading.magneticHeading)
                            .frame(height: 120)
                    } else {
                        Text("Heading not available")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Floor Level (for indoor positioning)
                Section("Indoor Positioning") {
                    if let floor = locationManager.location?.floor?.level {
                        HStack {
                            Text("Floor Level")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(floor)")
                        }
                    } else {
                        Text("Floor level not available")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Status Section
                Section("Status") {
                    HStack {
                        Text("Authorization")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(locationManager.authorizationStatus)
                    }
                    StatusRow(label: "Location Services", available: CLLocationManager.locationServicesEnabled())
                    StatusRow(label: "Heading Available", available: CLLocationManager.headingAvailable())
                }
            }
            .navigationTitle("Location & GPS")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        locationManager.requestLocation()
                    }) {
                        Image(systemName: "location.circle")
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var heading: CLHeading?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var authorizationStatus: String {
        switch manager.authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        
        withAnimation {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.heading = newHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - Helper Views

struct CoordinateRow: View {
    let label: String
    let value: Double
    let format: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(String(format: format, value))
                .monospacedDigit()
        }
    }
}

struct CompassView: View {
    let heading: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            
            // Direction indicators
            ForEach(0..<8) { i in
                VStack {
                    Text(directionLabel(i))
                        .font(.caption2)
                        .fontWeight(i % 2 == 0 ? .bold : .regular)
                    Spacer()
                }
                .rotationEffect(.degrees(Double(i) * 45))
            }
            .padding(8)
            
            // Needle
            VStack {
                Triangle()
                    .fill(Color.red)
                    .frame(width: 10, height: 40)
                Triangle()
                    .fill(Color.gray)
                    .frame(width: 10, height: 40)
                    .rotationEffect(.degrees(180))
            }
            .rotationEffect(.degrees(-heading))
        }
    }
    
    func directionLabel(_ index: Int) -> String {
        ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][index]
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    LocationView()
}
