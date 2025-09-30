import SwiftUI
import Charts

// MARK: - Extensions

private extension View {
    func tightChart() -> some View {
        self
            .chartLegend(.hidden)
            .chartPlotStyle { plot in
                plot.padding(.top, 0).padding(.bottom, 0)
            }
            .padding(.vertical, 0)
    }
}

// MARK: - EmptyStateCard

private struct EmptyStateCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.secondary.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [6,4]))
            VStack(spacing: 6) {
                Text(title).font(.headline).foregroundStyle(.secondary)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - DynamicsView

struct DynamicsView: View {
    @ObservedObject var store: SessionStore
    @Environment(\.dismiss) private var dismiss

    // MARK: Enums

    enum Mode: String, CaseIterable, Identifiable {
        case totals = "Totals", day = "Activity by day"
        var id: String { rawValue }
    }

    enum Span: String, CaseIterable, Identifiable {
        case days7 = "7 days", days30 = "30 days", days90 = "90 days", all = "All"
        var id: String { rawValue }
        var back: Int? {
            switch self {
            case .days7:  return 7
            case .days30: return 30
            case .days90: return 90
            case .all:    return nil
            }
        }
    }

    enum Resolution: String, CaseIterable, Identifiable {
        case hour = "Hour", min15 = "15 min"
        var id: String { rawValue }
        var minutes: Int { self == .hour ? 60 : 15 }
    }

    // MARK: State

    @State private var mode: Mode = .totals
    @State private var span: Span = .days30
    @State private var day: Date = Calendar.current.startOfDay(for: Date())
    @State private var resolution: Resolution = .hour

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Work analytics").font(.title2).bold()
                Spacer()
                Picker("", selection: $mode) {
                    ForEach(Mode.allCases) { m in Text(m.rawValue).tag(m) }
                }
                .pickerStyle(.segmented)
                Button {
                    dismiss()
                } label: {
                    Label("Close", systemImage: "xmark")
                }
                .keyboardShortcut(.cancelAction)
            }

            if mode == .totals {
                totalsView
            } else {
                perDayView
            }
        }
        .padding(16)
        .frame(minWidth: 640, minHeight: 480)
    }

    // MARK: Totals

    private var totalsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("", selection: $span) {
                    ForEach(Span.allCases) { s in Text(s.rawValue).tag(s) }
                }
                .pickerStyle(.segmented)
                Spacer()
            }

            let stats = dailyTotals(span: span)

            if stats.isEmpty {
                EmptyStateCard(
                    title: "No data yet",
                    subtitle: "Start a session to see your daily totals here."
                )
            } else {
                let totalSec = stats.reduce(0) { $0 + $1.totalSec }
                let daysCount = max(1, stats.count)
                let avgSec = totalSec / Double(daysCount)

                Chart(stats) { item in
                    BarMark(
                        x: .value("Date", item.date, unit: .day),
                        y: .value("Hours", item.totalSec / 3600.0)
                    )
                    .accessibilityLabel(Text(AppFormat.dateMedium(item.date)))
                    .accessibilityValue(Text("\(String(format: "%.1f", item.totalSec/3600.0)) h"))
                }
                .chartYAxisLabel("Hours")
                .tightChart()

                HStack(spacing: 24) {
                    Label("Total: \(AppFormat.hms(totalSec))", systemImage: "sum")
                    Label("Avg/day: \(AppFormat.hms(avgSec))", systemImage: "chart.bar.xaxis")
                    Spacer()
                }
                .font(.system(.body, design: .monospaced))

                List(stats.suffix(14).reversed()) { d in
                    HStack {
                        Text(AppFormat.dateMedium(d.date))
                        Spacer()
                        Text(AppFormat.hms(d.totalSec))
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: Per-Day

    private var perDayView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                DatePicker("Day:", selection: $day, displayedComponents: [.date])
                    .datePickerStyle(.field)
                    .labelsHidden()

                Picker("Resolution", selection: $resolution) {
                    ForEach(Resolution.allCases) { r in Text(r.rawValue).tag(r) }
                }
                .pickerStyle(.segmented)

                Spacer()
            }

            let bins = binsForDay(day, stepMinutes: resolution.minutes)

            if bins.isEmpty || bins.allSatisfy({ $0.seconds <= 0 }) {
                EmptyStateCard(
                    title: "No activity this day",
                    subtitle: "Run a session to see intra-day activity here."
                )
            } else {
                Chart(bins) { bin in
                    LineMark(
                        x: .value("Time", bin.start),
                        y: .value("Minutes", bin.seconds / 60.0)
                    )
                    .interpolationMethod(.monotone)

                    PointMark(
                        x: .value("Time", bin.start),
                        y: .value("Minutes", bin.seconds / 60.0)
                    )
                }
                .chartXScale(domain: xDomainForDay(day))
                .chartYAxisLabel("Minutes")
                .chartYScale(domain: 0...Double(resolution.minutes))
                .chartXAxis {
                    AxisMarks(preset: .aligned, position: .bottom, values: .stride(by: .hour)) { v in
                        AxisGridLine()
                        AxisTick()
                        if #available(macOS 14.0, iOS 17.0, *) {
                            AxisValueLabel(format: .dateTime.hour(.twoDigits(amPM: .omitted)))
                        } else if let date = v.as(Date.self) {
                            AxisValueLabel(AppFormat.dateMedium(date))
                        }
                    }
                }
                .tightChart()

                let dayTotal = bins.reduce(0) { $0 + $1.seconds }
                HStack(spacing: 24) {
                    Label("Total (day): \(AppFormat.hms(dayTotal))", systemImage: "clock")
                    Label("Points: \(bins.count)", systemImage: "point.3.connected.trianglepath.dotted")
                    Spacer()
                }
                .font(.system(.body, design: .monospaced))
            }
        }
    }

    // MARK: Aggregation (Daily Totals)

    struct DailyStat: Identifiable {
        let id = UUID()
        let date: Date
        let totalSec: Double
    }

    private func dailyTotals(span: Span) -> [DailyStat] {
        let sessions = store.sessions
        guard !sessions.isEmpty else { return [] }

        let cal = Calendar.current
        let endDay = cal.startOfDay(for: Date())
        let startDay: Date = {
            if let back = span.back {
                let from = cal.date(byAdding: .day, value: -back + 1, to: endDay) ?? endDay
                return cal.startOfDay(for: from)
            } else {
                let minDate = sessions.map { cal.startOfDay(for: $0.startedAt) }.min() ?? endDay
                return minDate
            }
        }()

        guard startDay <= endDay else { return [] }

        var bucket: [Date: Double] = [:]
        for s in sessions {
            let day = cal.startOfDay(for: s.startedAt)
            bucket[day, default: 0] += s.totalSec
        }

        var stats: [DailyStat] = []
        var d = startDay
        while d <= endDay {
            stats.append(.init(date: d, totalSec: bucket[d] ?? 0))
            guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        return stats
    }

    // MARK: Aggregation (Activity By Day)

    struct TimeBin: Identifiable {
        let id = UUID()
        let start: Date
        let seconds: Double
        let label: String
    }

    private func binsForDay(_ day: Date, stepMinutes: Int) -> [TimeBin] {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: day)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

        let binCount = (24 * 60) / stepMinutes
        var bins: [TimeBin] = []
        bins.reserveCapacity(binCount)

        for i in 0..<binCount {
            let start = cal.date(byAdding: .minute, value: i * stepMinutes, to: dayStart)!
            let label: String = {
                let comps = cal.dateComponents([.hour, .minute], from: start)
                let h = comps.hour ?? 0, m = comps.minute ?? 0
                return stepMinutes == 60 ? String(format: "%02d", h) : String(format: "%02d:%02d", h, m)
            }()
            bins.append(TimeBin(start: start, seconds: 0, label: label))
        }

        for s in store.sessions {
            let spanStart = max(s.startedAt, dayStart)
            let spanEnd   = min(s.endedAt, dayEnd)
            let span = spanEnd.timeIntervalSince(spanStart)
            guard span > 0, s.totalSec > 0 else { continue }

            let denom = s.endedAt.timeIntervalSince(s.startedAt)
            let rate = s.totalSec / (denom > 0 ? denom : span)

            for i in 0..<bins.count {
                let binStart = bins[i].start
                let binEnd   = cal.date(byAdding: .minute, value: stepMinutes, to: binStart)!
                let overlapStart = max(binStart, spanStart)
                let overlapEnd   = min(binEnd,   spanEnd)
                let overlap = overlapEnd.timeIntervalSince(overlapStart)
                if overlap > 0 {
                    let add = rate * overlap
                    bins[i] = TimeBin(start: bins[i].start,
                                      seconds: bins[i].seconds + add,
                                      label: bins[i].label)
                }
            }
        }

        return bins
    }
}

// MARK: - Helpers

private func xDomainForDay(_ day: Date) -> ClosedRange<Date> {
    let cal = Calendar.current
    let start = cal.startOfDay(for: day)
    let end   = cal.date(byAdding: .day, value: 1, to: start)!
    return start...end
}
