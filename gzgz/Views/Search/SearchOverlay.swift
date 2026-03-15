import SwiftUI

struct SearchOverlay: View {
    @Bindable var vm: SearchViewModel
    let onNavigateToNode: (ThoughtNode) -> Void

    var body: some View {
        if vm.isVisible {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gzTextSecondary)
                        .font(.system(size: 14))
                    TextField("Search thoughts...", text: $vm.query)
                        .textFieldStyle(.plain)
                        .font(GZFont.search())
                        .foregroundColor(.gzText)
                        .onChange(of: vm.query) { _, newValue in
                            try? vm.search(query: newValue)
                        }
                        .onKeyPress(.downArrow) {
                            vm.selectNext()
                            return .handled
                        }
                        .onKeyPress(.upArrow) {
                            vm.selectPrevious()
                            return .handled
                        }
                        .onKeyPress(.return) {
                            if let node = vm.selectedResult {
                                onNavigateToNode(node)
                                vm.toggle()
                            }
                            return .handled
                        }
                        .onKeyPress(.escape) {
                            vm.toggle()
                            return .handled
                        }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                if !vm.results.isEmpty {
                    Divider().foregroundColor(.gzChromeBorder)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(vm.results.enumerated()), id: \.element.id) { index, node in
                                HStack {
                                    Text(node.text.isEmpty ? "(empty)" : node.text)
                                        .font(GZFont.ui())
                                        .foregroundColor(.gzText)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    index == vm.selectedResultIndex
                                        ? Color.gzSelection
                                        : Color.clear
                                )
                                .onTapGesture {
                                    onNavigateToNode(node)
                                    vm.toggle()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 260)
                } else if !vm.query.isEmpty {
                    Divider().foregroundColor(.gzChromeBorder)
                    Text("No results")
                        .font(GZFont.ui(12))
                        .foregroundColor(.gzTextSecondary)
                        .padding(14)
                }
            }
            .frame(width: 380)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}
