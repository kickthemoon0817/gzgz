import SwiftUI

struct HistoryPanel: View {
    let history: HistoryManager
    let onJumpTo: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("History")
                .font(GZFont.uiBold(14))
                .foregroundColor(.gzText)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            Divider().foregroundColor(.gzChromeBorder)

            if history.entries.isEmpty {
                Text("No actions yet")
                    .font(GZFont.ui(12))
                    .foregroundColor(.gzTextSecondary)
                    .padding(12)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(history.entries.enumerated()), id: \.offset) { index, entry in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(index <= history.currentIndex ? Color.gzBrand : Color.gzTextSecondary.opacity(0.3))
                                    .frame(width: 5, height: 5)

                                Text(entry.displayName)
                                    .font(GZFont.ui(12))
                                    .foregroundColor(
                                        index <= history.currentIndex ? .gzText : .gzTextSecondary
                                    )
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
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
        .frame(width: 190)
        .background(Color.gzChrome)
    }
}
