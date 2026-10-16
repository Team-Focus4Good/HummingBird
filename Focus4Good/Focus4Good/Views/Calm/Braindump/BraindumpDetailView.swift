import SwiftUI
import PencilKit

// MARK: - Read-Only Canvas

/// A non-interactive PKCanvasView that displays a saved PKDrawing exactly as drawn.
struct ReadOnlyCanvasView: UIViewRepresentable {

    let drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.drawingPolicy = .pencilOnly   // disables all input
        canvas.isUserInteractionEnabled = false
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.isScrollEnabled = false
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }
}

// MARK: - Detail View

struct BraindumpDetailView: View {

    let entry: BrainDumpEntry

    @Environment(\.dismiss) private var dismiss
    @Environment(CalmCentreStore.self) private var store
    @State private var showDeleteConfirmation = false

    private var savedDrawing: PKDrawing? {
        guard let data = entry.drawingData, !data.isEmpty,
              let drawing = try? PKDrawing(data: data),
              !drawing.strokes.isEmpty else { return nil }
        return drawing
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Date
                Text(entry.createdAt, format: .dateTime.day().month(.wide).year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                // Drawing — read-only PKCanvasView
                if let drawing = savedDrawing {
                    ReadOnlyCanvasView(drawing: drawing)
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height - 200)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                        .padding(.bottom, 13)
                }

                // Text
                if !entry.content.isEmpty {
                    Text(entry.content)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
            }
            .padding(.top)
            .padding(.bottom, 32)
        }
        .background(AppTheme.appGradient.ignoresSafeArea())
        .navigationTitle(entry.title ?? "Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .confirmationDialog(
            "Delete this braindump?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    store.deleteBrainDumpEntry(entry)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This can't be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        BraindumpDetailView(
            entry: BrainDumpEntry(
                userId: UUID(),
                content: "I have so many things on my mind right now. Work is stressful and I need to relax.",
                pointsEarned: 10,
                createdAt: Date()
            )
        )
        .environment(CalmCentreStore.shared)
    }
}
