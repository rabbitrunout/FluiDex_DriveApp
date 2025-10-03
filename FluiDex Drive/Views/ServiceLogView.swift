import SwiftUI
import CoreData

struct ServiceLogView: View {
    var body: some View {
        ZStack {
            Color(hex: "#FFE082").ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Service Log")
                    .font(.title.bold())
                    .foregroundColor(.red)
                
                HStack {
                    Text("All").font(.headline).padding(8).background(Color.white.opacity(0.5)).cornerRadius(8)
                    Text("Oil").font(.headline)
                    Text("Tires").font(.headline)
                    Text("Fluids").font(.headline)
                    Text("Other").font(.headline)
                }
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundColor(.white)
                        VStack(alignment: .leading) {
                            Text("Oil Change").font(.headline).foregroundColor(.white)
                            Text("25,200 km • Next in 1,200 km")
                                .font(.subheadline).foregroundColor(.white.opacity(0.9))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(hex: "#FF7043"))
                    .cornerRadius(12)
                    
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.white)
                        VStack(alignment: .leading) {
                            Text("Inspection").font(.headline).foregroundColor(.white)
                            Text("82,000 km • Sep 2025")
                                .font(.subheadline).foregroundColor(.white.opacity(0.9))
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(hex: "#FF7043"))
                    .cornerRadius(12)
                    
                    Button(action: {}) {
                        Text("Add")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ServiceLogView()
}
