import SwiftUI

struct ContentView: View {
    @StateObject private var serviceVM = ServiceViewModel()
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "speedometer")
                }
            
            ServiceLogView(viewModel: serviceVM)
                .tabItem {
                    Label("Service Log", systemImage: "wrench.and.screwdriver")
                }
            
            AddServiceView(viewModel: serviceVM)
                .tabItem {
                    Label("Add Service", systemImage: "plus.circle.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
