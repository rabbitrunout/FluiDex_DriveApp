import SwiftUI
import CoreData

struct TripHUDView: View {

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true")
    )
    private var selectedCar: FetchedResults<Car>

    @StateObject private var tripManager: TripManager

    // UI state
    @State private var isExpanded: Bool = false

    init() {
        let context = PersistenceController.shared.container.viewContext

        // ✅ берём активную машину
        let req: NSFetchRequest<Car> = Car.fetchRequest()
        req.predicate = NSPredicate(format: "isSelected == true")
        let car = (try? context.fetch(req).first) ?? Car(context: context)

        _tripManager = StateObject(wrappedValue: TripManager(context: context, car: car))
    }

    var body: some View {
        VStack(spacing: 12) {

            headerRow

            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isExpanded)
        .onAppear {
            // если уже трекинг идёт — показываем expanded
            if tripManager.isTracking { isExpanded = true }
        }
        .onChange(of: tripManager.isTracking) { tracking in
            // авто-поведение: старт → expand, стоп → collapse
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                isExpanded = tracking
            }
        }
    }

    // MARK: - Header (collapsed row)
    private var headerRow: some View {
        HStack(spacing: 10) {
            Text("Trip Tracker")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Circle()
                .fill(tripManager.isTracking ? .green : .gray)
                .frame(width: 10, height: 10)

            Button {
                tripManager.requestPermissions()
                tripManager.start()
                // expand делается автоматически через onChange(isTracking)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                    Text(tripManager.isTracking ? "Running" : "Start")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.black)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color(hex: "#FFD54F"))
                .cornerRadius(14)
                .shadow(color: Color.yellow.opacity(0.25), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(tripManager.isTracking) // чтобы не нажимали Start снова

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .padding(.leading, 2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Expanded content
    private var expandedContent: some View {
        VStack(spacing: 12) {
            HStack {
                metric("Distance", "\(String(format: "%.2f", tripManager.totalDistance / 1000)) km")
                Spacer()
                metric("Duration", formatTime(tripManager.duration))
                Spacer()
                metric("Speed", "\(Int(tripManager.currentSpeedKmh)) km/h")
            }

            HStack(spacing: 14) {

                Button {
                    tripManager.stop()
                    // collapse сделается автоматически
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(16)
                    .shadow(color: Color.red.opacity(0.25), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(!tripManager.isTracking)

                Button {
                    // optional: быстрый ресет (если у тебя есть метод reset())
                    // tripManager.reset()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Small helpers
    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cyan)
        }
    }

    private func formatTime(_ sec: TimeInterval) -> String {
        let s = Int(sec)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.black, Color(hex: "#1A1A40")],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
        .ignoresSafeArea()

        TripHUDView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .padding()
    }
}



