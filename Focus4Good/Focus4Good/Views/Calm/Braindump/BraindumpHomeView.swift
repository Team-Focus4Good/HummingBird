import SwiftUI
import PencilKit

struct BraindumpHomeView: View {

    @Environment(UserStore.self) private var userStore
    @Environment(CalmCentreStore.self) private var store

    private var currentUserId: UUID {
        userStore.currentUser?.id ?? DummyData.currentUser.id
    }

    private var entries: [BrainDumpEntry] {
        // Only show entries that belong to this specific logged-in user
        store.recentBrainDumpEntries.filter { $0.userId == currentUserId }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    entriesList
                }
            }

            NavigationLink {
                BraindumpWriteView()
                    .toolbar(.hidden, for: .tabBar)
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.accentColor))
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .background(AppTheme.appGradient.ignoresSafeArea())
        .navigationTitle("Braindump")
        .toolbar(.hidden, for: .tabBar)
        .task(id: currentUserId) {
            await store.fetchBrainDumpEntries(userId: currentUserId)
        }
        .refreshable {
            await store.fetchBrainDumpEntries(userId: currentUserId)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("No Dumps Yet")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Tap + to write, speak, or draw your first braindump.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Entries List (LazyVStack in ScrollView)

    private var entriesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(entries) { entry in
                    NavigationLink {
                        BraindumpDetailView(entry: entry)
                            .toolbar(.hidden, for: .tabBar)
                    } label: {
                        entryCard(entry)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteEntry(entry)
                        } label: {
                            Label("Delete Dump", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 96)
        }
    }

    private func entryCard(_ entry: BrainDumpEntry) -> some View {
        HStack(spacing: 14) {
            // Thumbnail or icon
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
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Image(systemName: "doc.text.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentColor.opacity(0.12))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 5) {
                // Title (user-given name) or fallback
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                } else if !entry.content.isEmpty {
                    Text(entry.content)
                        .font(.body)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                } else {
                    Text("Drawing Note")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 8) {
                    Text(entry.createdAt, format: .dateTime.day().month(.abbreviated).hour().minute())
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if entry.drawingData != nil && !entry.content.isEmpty {
                        Label("Drawing", systemImage: "hand.draw")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    private func deleteEntry(_ entry: BrainDumpEntry) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            store.deleteBrainDumpEntry(entry)
        }
    }
}

#Preview {
    NavigationStack {
        BraindumpHomeView()
            .environment(CalmCentreStore.shared)
    }
}
