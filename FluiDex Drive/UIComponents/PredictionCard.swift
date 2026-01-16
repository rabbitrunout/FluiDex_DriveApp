import SwiftUI

struct PredictionCard: View {
    let carMileage: Int32
    let prediction: MaintenancePrediction

    // Real computed progress (history only)
    private var computedProgress: Double {
        let p = MaintenanceProgress.combined(carMileage: carMileage, now: Date(), p: prediction)
        return min(max(p, 0), 1)
    }

    // What we show in the ProgressView
    private var displayProgress: Double {
        prediction.isFallback ? 0.35 : computedProgress
    }

    private var progressPercent: Int {
        Int((displayProgress * 100).rounded())
    }

    private var confidencePercent: Int {
        Int((prediction.confidence * 100).rounded())
    }

    private var basisText: String {
        prediction.basis == "history" ? "Based on history" : "Fallback estimate"
    }

    private var kmText: String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf.string(from: NSNumber(value: prediction.nextMileage)) ?? "\(prediction.nextMileage)"
    }

    private var dateText: String {
        prediction.nextDate.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - Status (single source of truth for history)

    private var status: MaintenanceProgress.Status {
        MaintenanceProgress.status(carMileage: carMileage, now: Date(), p: prediction)
    }

    // MARK: - Fallback appearance (confidence-based)

    private var fallbackStatusText: String {
        if prediction.confidence < 0.40 { return "Low confidence" }
        if prediction.confidence < 0.60 { return "Estimate" }
        return "High confidence"
    }

    private var fallbackStatusColor: Color {
        if prediction.confidence < 0.40 { return .gray }
        if prediction.confidence < 0.60 { return .cyan }
        return .yellow
    }

    private var fallbackProgressColor: Color {
        if prediction.confidence < 0.40 { return .gray }
        if prediction.confidence < 0.60 { return .cyan }
        return .yellow
    }

    // MARK: - Colors for history progress (rules you asked)

    private var historyProgressColor: Color {
        switch computedProgress {
        case ..<0.6:
            return .cyan
        case 0.6..<0.85:
            return .yellow
        default:
            return .red
        }
    }

    private var progressColor: Color {
        prediction.isFallback ? fallbackProgressColor : historyProgressColor
    }

    private var statusText: String? {
        if prediction.isFallback {
            return fallbackStatusText
        }
        switch status {
        case .estimate: return "Estimate"
        case .dueSoon: return "Due soon"
        case .overdue: return "Overdue"
        case .normal: return nil
        }
    }

    private var statusColor: Color {
        if prediction.isFallback {
            return fallbackStatusColor
        }
        switch status {
        case .estimate, .normal:
            return .cyan
        case .dueSoon:
            return .yellow
        case .overdue:
            return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text(prediction.type)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                // Confidence badge
                Text("\(confidencePercent)%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            }

            Text("Next service: \(dateText) • ~\(kmText) km")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.75))

            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: displayProgress)
                    .tint(progressColor)

                HStack {
                    if let statusText {
                        Text(statusText)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(statusColor)
                    } else {
                        Text("\(progressPercent)% until due")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    Text(basisText)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.08))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
        )
    }
}
