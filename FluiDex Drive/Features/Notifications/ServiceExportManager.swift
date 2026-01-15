import Foundation
import UIKit
import CoreData

final class ServiceExportManager {
    static let shared = ServiceExportManager()
    private init() {}

    // MARK: - CSV

    func makeCSV(car: Car, records: [ServiceRecord]) -> String {
        let header = [
            "Car","Year","Type","Date","Mileage",
            "Parts Cost","Labor Cost","Total Cost",
            "Note","Next Service KM","Next Service Date"
        ]
        var lines: [String] = []
        lines.append(header.joined(separator: ","))

        let df = DateFormatter()
        df.dateStyle = .medium

        let carName = escapeCSV(car.name ?? "Car")
        let carYear = escapeCSV(car.year ?? "—")

        for r in records {
            let type = escapeCSV(r.type ?? "Other")
            let date = escapeCSV(r.date.map { df.string(from: $0) } ?? "—")
            let mileage = "\(r.mileage)"
            let parts = String(format: "%.2f", r.costParts)
            let labor = String(format: "%.2f", r.costLabor)
            let total = String(format: "%.2f", r.totalCost)
            let note = escapeCSV(r.note ?? "")

            let nextKm = r.nextServiceKm > 0 ? "\(r.nextServiceKm)" : ""
            let nextDate = escapeCSV(r.nextServiceDate.map { df.string(from: $0) } ?? "")

            let row = [
                carName, carYear, type, date, mileage,
                parts, labor, total,
                note, nextKm, nextDate
            ]
            lines.append(row.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    func writeCSVToTempFile(fileName: String, csv: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        guard let data = csv.data(using: .utf8) else { throw NSError(domain: "CSV", code: 1) }
        try data.write(to: url, options: .atomic)
        return url
    }

    private func escapeCSV(_ s: String) -> String {
        var str = s.replacingOccurrences(of: "\"", with: "\"\"")
        if str.contains(",") || str.contains("\n") || str.contains("\"") {
            str = "\"\(str)\""
        }
        return str
    }

    // MARK: - PDF (A4 + grid + grouping + totals + icon)

    func makePDFDataA4(car: Car, records: [ServiceRecord]) -> Data {
        // A4 @ 72dpi
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 36

        let df = DateFormatter()
        df.dateStyle = .medium

        // Group by normalized type (so "Tires" and "Tire rotation" can land in Tires if you want)
        let grouped = Dictionary(grouping: records) { normalizeType($0.type ?? "Other") }
        let sortedKeys = grouped.keys.sorted()

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            var y: CGFloat = margin

            // Column layout
            // Date | Mileage | Total | Next Date | Next Km
            let tableX = margin
            let tableW = pageRect.width - margin * 2

            // widths sum ~ tableW
            let colW: [CGFloat] = [
                tableW * 0.22, // Date
                tableW * 0.16, // Mileage
                tableW * 0.14, // Total
                tableW * 0.26, // Next Date
                tableW * 0.22  // Next Km
            ]
            let colX: [CGFloat] = {
                var xs: [CGFloat] = [tableX]
                for i in 0..<colW.count-1 {
                    xs.append(xs[i] + colW[i])
                }
                return xs
            }()

            let titleFont = UIFont.boldSystemFont(ofSize: 20)
            let subFont = UIFont.systemFont(ofSize: 11)
            let sectionFont = UIFont.boldSystemFont(ofSize: 13)
            let headerFont = UIFont.boldSystemFont(ofSize: 10)
            let rowFont = UIFont.systemFont(ofSize: 10)
            let smallFont = UIFont.systemFont(ofSize: 9)

            let gridColor = UIColor(white: 0.88, alpha: 1)
            let headerFill = UIColor(white: 0.96, alpha: 1)
            let sectionFill = UIColor(white: 0.94, alpha: 1)

            func drawText(_ text: String, font: UIFont, color: UIColor = .black, x: CGFloat, y: CGFloat, w: CGFloat, align: NSTextAlignment = .left) {
                let p = NSMutableParagraphStyle()
                p.alignment = align
                p.lineBreakMode = .byTruncatingTail
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: p
                ]
                (text as NSString).draw(in: CGRect(x: x, y: y, width: w, height: 20), withAttributes: attrs)
            }

            func drawLine(_ from: CGPoint, _ to: CGPoint, _ color: UIColor = gridColor, _ width: CGFloat = 1) {
                let path = UIBezierPath()
                path.move(to: from)
                path.addLine(to: to)
                color.setStroke()
                path.lineWidth = width
                path.stroke()
            }

            func fillRect(_ rect: CGRect, _ color: UIColor) {
                color.setFill()
                UIBezierPath(rect: rect).fill()
            }

            func newPageIfNeeded(extraNeeded: CGFloat) {
                if y + extraNeeded > pageRect.height - margin {
                    ctx.beginPage()
                    y = margin
                    drawPageHeader()
                }
            }

            func drawIconAndHeader() {
                // icon
                if let img = UIImage(systemName: "car.fill") {
                    let iconRect = CGRect(x: margin, y: y, width: 22, height: 22)
                    UIColor.systemTeal.setFill()
                    img.withTintColor(.systemTeal, renderingMode: .alwaysOriginal).draw(in: iconRect)
                }

                drawText("FluiDex Drive — Service History", font: titleFont, color: .black,
                         x: margin + 30, y: y - 2, w: pageRect.width - margin*2 - 30)

                y += 26

                let carLine = "\(car.name ?? "Car") • \(car.year ?? "—") • \(Int(car.mileage)) km"
                drawText(carLine, font: subFont, color: .darkGray, x: margin, y: y, w: pageRect.width - margin*2)

                y += 18
                drawLine(CGPoint(x: margin, y: y), CGPoint(x: pageRect.width - margin, y: y), UIColor(white: 0.85, alpha: 1))
                y += 14
            }

            func drawPageHeader() {
                // small header on every page
                drawText("Service History", font: UIFont.boldSystemFont(ofSize: 14), color: .black,
                         x: margin, y: y, w: pageRect.width - margin*2)
                y += 18
                drawLine(CGPoint(x: margin, y: y), CGPoint(x: pageRect.width - margin, y: y), UIColor(white: 0.85, alpha: 1))
                y += 10
            }

            func drawTableHeaderRow() {
                let rowH: CGFloat = 20
                let rect = CGRect(x: tableX, y: y, width: tableW, height: rowH)
                fillRect(rect, headerFill)

                drawText("Date", font: headerFont, x: colX[0] + 6, y: y + 4, w: colW[0] - 12)
                drawText("Mileage", font: headerFont, x: colX[1] + 6, y: y + 4, w: colW[1] - 12)
                drawText("Total", font: headerFont, x: colX[2] + 6, y: y + 4, w: colW[2] - 12)
                drawText("Next Date", font: headerFont, x: colX[3] + 6, y: y + 4, w: colW[3] - 12)
                drawText("Next KM", font: headerFont, x: colX[4] + 6, y: y + 4, w: colW[4] - 12)

                // outer
                drawLine(CGPoint(x: tableX, y: y), CGPoint(x: tableX + tableW, y: y))
                drawLine(CGPoint(x: tableX, y: y + rowH), CGPoint(x: tableX + tableW, y: y + rowH))
                drawLine(CGPoint(x: tableX, y: y), CGPoint(x: tableX, y: y + rowH))
                drawLine(CGPoint(x: tableX + tableW, y: y), CGPoint(x: tableX + tableW, y: y + rowH))

                // vertical grid
                var vx = tableX
                for w in colW.dropLast() {
                    vx += w
                    drawLine(CGPoint(x: vx, y: y), CGPoint(x: vx, y: y + rowH))
                }

                y += rowH
            }

            func drawSectionHeader(_ title: String) {
                let rowH: CGFloat = 22
                newPageIfNeeded(extraNeeded: rowH + 24)

                let rect = CGRect(x: tableX, y: y, width: tableW, height: rowH)
                fillRect(rect, sectionFill)
                drawText(title, font: sectionFont, x: tableX + 8, y: y + 4, w: tableW - 16)

                drawLine(CGPoint(x: tableX, y: y), CGPoint(x: tableX + tableW, y: y))
                drawLine(CGPoint(x: tableX, y: y + rowH), CGPoint(x: tableX + tableW, y: y + rowH))
                drawLine(CGPoint(x: tableX, y: y), CGPoint(x: tableX, y: y + rowH))
                drawLine(CGPoint(x: tableX + tableW, y: y), CGPoint(x: tableX + tableW, y: y + rowH))

                y += rowH
                drawTableHeaderRow()
            }

            func drawDataRow(date: String, mileage: String, total: String, nextDate: String, nextKm: String, note: String?) {
                let rowH: CGFloat = 18
                newPageIfNeeded(extraNeeded: rowH + (note == nil ? 0 : 14) + 10)

                // row border
                drawLine(CGPoint(x: tableX, y: y), CGPoint(x: tableX + tableW, y: y))
                drawLine(CGPoint(x: tableX, y: y + rowH), CGPoint(x: tableX + tableW, y: y + rowH))
                drawLine(CGPoint(x: tableX, y: y), CGPoint(x: tableX, y: y + rowH))
                drawLine(CGPoint(x: tableX + tableW, y: y), CGPoint(x: tableX + tableW, y: y + rowH))

                var vx = tableX
                for w in colW.dropLast() {
                    vx += w
                    drawLine(CGPoint(x: vx, y: y), CGPoint(x: vx, y: y + rowH))
                }

                drawText(date, font: rowFont, x: colX[0] + 6, y: y + 3, w: colW[0] - 12)
                drawText(mileage, font: rowFont, x: colX[1] + 6, y: y + 3, w: colW[1] - 12)
                drawText(total, font: rowFont, x: colX[2] + 6, y: y + 3, w: colW[2] - 12)
                drawText(nextDate, font: rowFont, x: colX[3] + 6, y: y + 3, w: colW[3] - 12)
                drawText(nextKm, font: rowFont, x: colX[4] + 6, y: y + 3, w: colW[4] - 12)

                y += rowH

                if let note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    drawText("Note: \(note)", font: smallFont, color: .darkGray,
                             x: tableX + 8, y: y + 2, w: tableW - 16)
                    y += 14
                }
            }

            func drawSectionTotal(_ total: Double) {
                let rowH: CGFloat = 18
                newPageIfNeeded(extraNeeded: rowH + 10)

                drawLine(CGPoint(x: tableX, y: y), CGPoint(x: tableX + tableW, y: y), UIColor(white: 0.80, alpha: 1), 1)
                y += 6
                drawText("Type total:", font: UIFont.boldSystemFont(ofSize: 10), color: .black,
                         x: colX[0] + 6, y: y, w: colW[0] + colW[1] - 12)

                drawText("$" + String(format: "%.2f", total), font: UIFont.boldSystemFont(ofSize: 10), color: .black,
                         x: colX[2] + 6, y: y, w: colW[2] - 12)

                y += rowH
            }

            func drawGrandTotals(perType: [(String, Double)], grand: Double) {
                newPageIfNeeded(extraNeeded: 140)

                y += 8
                drawLine(CGPoint(x: margin, y: y), CGPoint(x: pageRect.width - margin, y: y), UIColor(white: 0.80, alpha: 1), 1)
                y += 14

                drawText("Totals by Type", font: UIFont.boldSystemFont(ofSize: 13), color: .black,
                         x: margin, y: y, w: pageRect.width - margin*2)
                y += 16

                for (t, val) in perType.sorted(by: { $0.0 < $1.0 }) {
                    drawText("• \(t)", font: UIFont.systemFont(ofSize: 11), color: .black,
                             x: margin, y: y, w: 260)
                    drawText("$" + String(format: "%.2f", val), font: UIFont.systemFont(ofSize: 11), color: .black,
                             x: pageRect.width - margin - 120, y: y, w: 120, align: .right)
                    y += 14
                }

                y += 10
                drawLine(CGPoint(x: margin, y: y), CGPoint(x: pageRect.width - margin, y: y), UIColor(white: 0.80, alpha: 1), 1)
                y += 10

                drawText("Grand Total", font: UIFont.boldSystemFont(ofSize: 12), color: .black,
                         x: margin, y: y, w: 260)

                drawText("$" + String(format: "%.2f", grand), font: UIFont.boldSystemFont(ofSize: 12), color: .black,
                         x: pageRect.width - margin - 140, y: y, w: 140, align: .right)
                y += 18

                let exported = df.string(from: Date())
                drawText("Exported: \(exported)", font: UIFont.systemFont(ofSize: 9), color: .darkGray,
                         x: margin, y: y, w: pageRect.width - margin*2)
                y += 12
            }

            // ---------- Start PDF ----------
            ctx.beginPage()
            drawIconAndHeader()

            var totalsByType: [(String, Double)] = []
            var grandTotal: Double = 0

            for key in sortedKeys {
                let list = (grouped[key] ?? [])
                    .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }

                // Section header + table header
                drawSectionHeader(key)

                var typeTotal: Double = 0

                for rec in list {
                    let dateStr = df.string(from: rec.date ?? Date())
                    let mileageStr = "\(rec.mileage) km"
                    let totalStr = "$" + String(format: "%.2f", rec.totalCost)

                    let nextDateStr = rec.nextServiceDate.map { df.string(from: $0) } ?? "—"
                    let nextKmStr = rec.nextServiceKm > 0 ? "\(rec.nextServiceKm) km" : "—"

                    drawDataRow(
                        date: dateStr,
                        mileage: mileageStr,
                        total: totalStr,
                        nextDate: nextDateStr,
                        nextKm: nextKmStr,
                        note: rec.note
                    )

                    typeTotal += rec.totalCost
                    grandTotal += rec.totalCost
                }

                drawSectionTotal(typeTotal)
                totalsByType.append((key, typeTotal))
                y += 6
            }

            drawGrandTotals(perType: totalsByType, grand: grandTotal)
        }
    }

    func writePDFToTempFile(fileName: String, data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Helpers

    private func normalizeType(_ raw: String) -> String {
        let t = raw.lowercased()
        if t.contains("oil") { return "Oil" }
        if t.contains("brake") { return "Brakes" }
        if t.contains("battery") { return "Battery" }
        if t.contains("tire") { return "Tires" }
        if t.contains("fluid") { return "Fluids" }
        if t.contains("inspect") || t.contains("filter") { return "Inspection" }
        return raw.isEmpty ? "Other" : raw
    }
}
