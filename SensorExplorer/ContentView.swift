import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MotionSensorsView()
                .tabItem {
                    Label("Motion", systemImage: "gyroscope")
                }
            
            EnvironmentSensorsView()
                .tabItem {
                    Label("Environment", systemImage: "sun.max")
                }
            
            LocationView()
                .tabItem {
                    Label("Location", systemImage: "location.fill")
                }
            
            BiometricView()
                .tabItem {
                    Label("Biometric", systemImage: "faceid")
                }
            
            ProximityView()
                .tabItem {
                    Label("Proximity", systemImage: "antenna.radiowaves.left.and.right")
                }
        }
    }
}

#Preview {
    ContentView()
}
