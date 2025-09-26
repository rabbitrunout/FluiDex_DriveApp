import SwiftUI

struct AddServiceView: View {
    @ObservedObject var viewModel: ServiceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var type: String = ""
    @State private var date: Date = Date()
    @State private var mileage: String = ""
    @State private var cost: String = ""
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#00B8D4"), Color(hex: "#4DD0E1")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Add Service")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                VStack(spacing: 15) {
                    TextField("Service Type (e.g. Oil Change)", text: $type)
                        .textFieldStyle(RoundedTextFieldStyle())
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    
                    TextField("Mileage (km)", text: $mileage)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedTextFieldStyle())
                    
                    TextField("Cost ($)", text: $cost)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedTextFieldStyle())
                }
                .padding(.horizontal, 20)
                
                Button(action: {
                    if let mileageInt = Int(mileage), let costDouble = Double(cost) {
                        viewModel.addService(type: type, date: date, mileage: mileageInt, cost: costDouble)
                        
                        // Закрываем экран
                        dismiss()
                    }
                }) {
                    Text("Save Service")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(12)
                        .shadow(color: .yellow.opacity(0.7), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
        }
    }
}

#Preview {
    AddServiceView(viewModel: ServiceViewModel())
}
