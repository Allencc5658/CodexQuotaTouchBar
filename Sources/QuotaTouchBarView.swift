import AppKit

final class QuotaTouchBarView: NSView {
    var quota: QuotaState? { didSet { needsDisplay = true } }
    var message: String? { didSet { needsDisplay = true } }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor(calibratedWhite: 0.12, alpha: 1).setFill()
        bounds.fill()

        guard let quota = quota else {
            drawText(message ?? L10n.text("touch_bar_loading"), x: 9, y: 8, width: bounds.width - 18,
                     size: 12, color: .white, bold: false)
            return
        }

        let rows: [(String, QuotaWindow?, Bool)] = [
            quota.showsFiveHour ? (L10n.text("five_hour_touch"), quota.fiveHour, false) : nil,
            quota.showsWeekly ? (L10n.text("week_touch"), quota.weekly, true) : nil
        ].compactMap { $0 }

        if rows.isEmpty {
            drawText(L10n.text("no_quota_window"), x: 9, y: 8, width: bounds.width - 18,
                     size: 12, color: .white, bold: false)
            return
        }
        for (index, row) in rows.enumerated() {
            let y: CGFloat = rows.count == 1 ? 8 : (index == 0 ? 1 : 16)
            drawRow(label: row.0, window: row.1, weekly: row.2, y: y)
        }
    }

    private func drawRow(label: String, window: QuotaWindow?, weekly: Bool, y: CGFloat) {
        drawText(label, x: 6, y: y, width: 40, size: 10.5, color: .white, bold: true)

        let segments = 12
        let barX: CGFloat = 51
        let segmentWidth: CGFloat = 9
        let gap: CGFloat = 2
        let filled = Int(((window?.remainingPercent ?? 0) / 100 * Double(segments)).rounded())
        let color: NSColor
        switch window?.remainingPercent {
        case .some(let value) where value <= 20: color = .systemRed
        case .some(let value) where value <= 45: color = .systemOrange
        case .some: color = .systemGreen
        case .none: color = .systemGray
        }
        for index in 0..<segments {
            let frame = NSRect(x: barX + CGFloat(index) * (segmentWidth + gap),
                               y: y + 3, width: segmentWidth, height: 7)
            let path = NSBezierPath(roundedRect: frame, xRadius: 1.5, yRadius: 1.5)
            (index < filled ? color : NSColor(calibratedWhite: 0.34, alpha: 1)).setFill()
            path.fill()
        }

        let detail: String
        if window == nil {
            detail = L10n.text("no_data")
        } else {
            detail = L10n.format("touch_bar_detail", QuotaText.percent(window),
                                 QuotaText.reset(window, weekly: weekly))
        }
        drawText(detail, x: 193, y: y, width: bounds.width - 198,
                 size: 10.5, color: .white, bold: false)
    }

    private func drawText(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat,
                          size: CGFloat, color: NSColor, bold: Bool) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        let font = NSFont.systemFont(ofSize: size, weight: bold ? .semibold : .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: color, .paragraphStyle: paragraph
        ]
        (text as NSString).draw(in: NSRect(x: x, y: y, width: max(0, width), height: 14),
                                withAttributes: attributes)
    }
}
