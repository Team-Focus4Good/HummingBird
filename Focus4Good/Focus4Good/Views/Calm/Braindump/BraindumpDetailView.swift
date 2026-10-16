import SwiftUI
import PencilKit

struct BraindumpDetailView: View {

    let entry: BrainDumpEntry
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Date
                Text(entry.createdAt, format: .dateTime.day().month(.wide).year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Drawing
                if let data = entry.drawingData, !data.isEmpty,
                   let drawing = try? PKDrawing(data: data), !drawing.strokes.isEmpty {
                    let drawingBounds = drawing.bounds
                    let safeRect = (drawingBounds.isNull || drawingBounds.isInfinite)
                        ? CGRect(x: 0, y: 0, width: 300, height: 300)
                        : drawingBounds
                    let image = drawing.image(from: safeRect, scale: 2.0)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                        )
                }

                // Text
                if !entry.content.isEmpty {
                    Text(entry.content)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .background(AppTheme.appGradient.ignoresSafeArea())
        .navigationTitle(entry.title ?? "Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    BraindumpDetailView(
        entry: BrainDumpEntry(
            userId: UUID(),
            content: "I have so many things on my mind right now. Work is stressful and I need to relax.",
            pointsEarned: 10,
            createdAt: Date()
        )
    )
}
