import SwiftUI

struct SearchOverlay: View {
    @Bindable var vm: SearchViewModel
    let onNavigateToNode: (ThoughtNode) -> Void

    var body: some View {
        if vm.isVisible {
            VStack(spacing: 0) {
                // Search input
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gzTextSecondary)
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
                .padding(12)
                .background(Color.gzNodeFill)

                Divider()

                // Results
                if !vm.results.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(vm.results.enumerated()), id: \.element.id) { index, node in
                                HStack {
                                    Text(node.text.isEmpty ? "(empty)" : node.text)
                                        .font(GZFont.node())
                                        .foregroundColor(.gzText)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
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
                    .frame(maxHeight: 300)
                } else if !vm.query.isEmpty {
                    Text("No results")
                        .font(GZFont.label())
                        .foregroundColor(.gzTextSecondary)
                        .padding(12)
                }
            }
            .frame(width: 400)
            .background(Color.gzBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        }
    }
}
