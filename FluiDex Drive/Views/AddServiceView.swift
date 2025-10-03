import SwiftUI
import CoreData

struct AddServiceView: View {
    var body: some View {
        VStack {
            Text("Add Service")
                .font(.title.bold())
                .padding()
            Spacer()
            Text("Form coming soon...")
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

#Preview {
    AddServiceView()
}
