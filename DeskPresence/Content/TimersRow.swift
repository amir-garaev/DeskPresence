import SwiftUI

// MARK: - TimersRow

struct TimersRow: View {
    @ObservedObject var tracker: SessionTracker

    var body: some View {
        HStack(spacing: 24) {
            TimerBlock(
                title: "Current session",
                value: AppFormat.hms(tracker.currentSec)
            )

            TimerBlock(
                title: "Total",
                value: AppFormat.hms(tracker.totalSec + tracker.currentSec)
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - TimerBlock

private struct TimerBlock: View {
    let title: String
    let value: String

    @ScaledMetric(relativeTo: .title2) private var valueSize: CGFloat = 32

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: valueSize, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(value))
    }
}
