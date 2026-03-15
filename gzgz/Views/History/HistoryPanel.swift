import SwiftUI

struct HistoryPanel: View {
    let history: HistoryManager
    let onJumpTo: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("History")
                .font(GZFont.nodeTitle())
                .foregroundColor(.gzText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            if history.entries.isEmpty {
                Text("No actions yet")
                    .font(GZFont.label())
                    .foregroundColor(.gzTextSecondary)
                    .padding(12)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(history.entries.enumerated()), id: \.offset) { index, entry in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(index <= history.currentIndex ? Color.gzPrimary : Color.gzTextSecondary.opacity(0.3))
                                    .frame(width: 6, height: 6)

                                Text(entry.displayName)
                                    .font(GZFont.label())
                                    .foregroundColor(
                                        index <= history.currentIndex ? .gzText : .gzTextSecondary
                                    )
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                index == history.currentIndex
                                    ? Color.gzSelection
                                    : Color.clear
                            )
                            .onTapGesture {
                                onJumpTo(index)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 200)
        .background(Color.gzBackground)
    }
}
