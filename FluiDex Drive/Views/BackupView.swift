import SwiftUI
import CoreData

struct BackupView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var statusMessage = ""

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("⚙️ Data Backup & Restore")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 10, y: 4)
                    .padding(.top, 40)

                Text(statusMessage)
                    .foregroundColor(.white.opacity(0.8))
                    .font(.footnote)

                // 💾 Экспорт
                Button {
                    if let url = DataBackupManager.shared.exportData(from: viewContext) {
                        statusMessage = "✅ Backup saved to \(url.lastPathComponent)"
                    } else {
                        statusMessage = "❌ Failed to export data"
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Backup")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cyan)
                    .cornerRadius(12)
                    .shadow(color: .cyan.opacity(0.5), radius: 6, y: 3)
                }

                // 📥 Импорт
                Button {
                    DataBackupManager.shared.importData(to: viewContext)
                    statusMessage = "✅ Data restored successfully!"
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Import Backup")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow)
                    .cornerRadius(12)
                    .shadow(color: .yellow.opacity(0.5), radius: 6, y: 3)
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    BackupView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
