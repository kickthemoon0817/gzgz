import SwiftUI

struct CanvasSidebar: View {
    @Bindable var vm: CanvasViewModel
    @State private var isAddingCanvas = false
    @State private var newCanvasName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Canvases")
                    .font(GZFont.uiBold(14))
                    .foregroundColor(.gzText)
                Spacer()
                Button(action: { isAddingCanvas = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.gzTextSecondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider().foregroundColor(.gzChromeBorder)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(vm.canvases) { canvas in
                        HStack {
                            Text(canvas.name)
                                .font(GZFont.ui())
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

            if isAddingCanvas {
                HStack {
                    TextField("Canvas name", text: $newCanvasName, onCommit: {
                        let name = newCanvasName.isEmpty ? "Untitled" : newCanvasName
                        try? vm.createCanvas(name: name)
                        newCanvasName = ""
                        isAddingCanvas = false
                    })
                    .textFieldStyle(.plain)
                    .font(GZFont.ui())
                    .padding(8)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 170)
        .background(Color.gzChrome)
    }
}
