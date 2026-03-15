import SwiftUI

struct CanvasSidebar: View {
    @Bindable var vm: CanvasViewModel
    @State private var isAddingCanvas = false
    @State private var newCanvasName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Canvases")
                    .font(GZFont.nodeTitle())
                    .foregroundColor(.gzText)
                Spacer()
                Button(action: { isAddingCanvas = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.gzPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Canvas list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(vm.canvases) { canvas in
                        HStack {
                            Text(canvas.name)
                                .font(GZFont.node())
                                .foregroundColor(.gzText)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            vm.currentCanvasId == canvas.id
                                ? Color.gzSelection
                                : Color.clear
                        )
                        .onTapGesture {
                            try? vm.switchCanvas(id: canvas.id!)
                        }
                    }
                }
            }

            Spacer()

            // New canvas input
            if isAddingCanvas {
                HStack {
                    TextField("Canvas name", text: $newCanvasName, onCommit: {
                        let name = newCanvasName.isEmpty ? "Untitled" : newCanvasName
                        try? vm.createCanvas(name: name)
                        newCanvasName = ""
                        isAddingCanvas = false
                    })
                    .textFieldStyle(.plain)
                    .font(GZFont.node())
                    .padding(8)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 180)
        .background(Color.gzBackground)
    }
}
