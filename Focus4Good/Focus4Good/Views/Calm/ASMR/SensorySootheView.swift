import SwiftUI

struct SensorySootheView: View {

    @Environment(CalmCentreStore.self) private var store
    @Environment(UserStore.self) private var userStore

    @State private var selectedSound: AsmrSound?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                
                // 1. Top Section: 5 Playlists (Horizontally Scrollable)
                playlistsSection
                
                // 2. Favourites Section (always visible; placeholder if empty)
                favouriteSoundsSection
                
                // 3. Recently Played Sounds Section (always visible; placeholder if empty)
                recentlyPlayedSoundsSection
            }
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(AppTheme.appGradient.ignoresSafeArea())
        .navigationTitle("ASMR Sounds")
        .navigationBarTitleDisplayMode(.large)
        .hideTabBar()
        .onAppear { 
            if let userId = userStore.currentUser?.id {
                Task { await store.fetchFavouriteAsmrSounds(userId: userId) }
            }
        }
    }

    // MARK: - Playlists (5 Main Cards)

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(ASMRData.playlists) { playlist in
                        NavigationLink(destination: ASMRPlaylistDetailView(playlist: playlist)) {
                            playlistCard(playlist: playlist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }

    private func playlistCard(playlist: ASMRPlaylist) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Background (Image or Placeholder Color)
            if !playlist.coverImageName.isEmpty {
                Image(playlist.coverImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 280, height: 280)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(hex: playlist.placeholderColorHex).gradient)
            }
            
            // Gradient Overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                
                Text(playlist.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 280, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(hex: playlist.placeholderColorHex).opacity(0.3), radius: 8, x: 0, y: 4)
    }

    // MARK: - Favourites Section

    private var favouriteSoundsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Your Favourites")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)

            if store.favouriteAsmrSounds.isEmpty {
                favouriteSoundsPlaceholder
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(store.favouriteAsmrSounds) { sound in
                            Button {
                                selectedSound = sound
                                store.playAsmrSound(sound)
                                store.showGlobalASMRPlayer = true
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    if !sound.imageUrl.isEmpty {
                                        Image(sound.imageUrl)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    } else {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(Color(.systemGray5))
                                            .frame(width: 120, height: 120)
                                            .overlay(
                                                Image(systemName: "waveform")
                                                    .font(.title2)
                                                    .foregroundStyle(.secondary)
                                            )
                                    }

                                    Text(sound.name)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .frame(width: 120, height: 32, alignment: .topLeading)
                                }
                                .frame(width: 120)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var favouriteSoundsPlaceholder: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "heart")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("No favourite sounds yet")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("Tap the heart on any sound while playing to keep it here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - Recently Played Sounds Section

    private var recentlyPlayedSoundsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recently Played Sounds")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if store.recentAsmrSounds.isEmpty {
                recentlyPlayedSoundsPlaceholder
            } else {
                // Show 4 sounds max, and scroll the rest in this area
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 10) {
                        ForEach(store.recentAsmrSounds, id: \.name) { sound in
                            soundRow(sound)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 2)
                }
                .frame(height: min(CGFloat(store.recentAsmrSounds.count) * 76 + CGFloat(max(0, store.recentAsmrSounds.count - 1)) * 10, 334))
            }
        }
    }

    private var recentlyPlayedSoundsPlaceholder: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "waveform")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("No recently played sounds")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("Play any ASMR sound to see it here for quick access.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }

    private func soundRow(_ sound: AsmrSound) -> some View {
        Button {
            selectedSound = sound
            store.playAsmrSound(sound)
            store.showGlobalASMRPlayer = true
        } label: {
            HStack(spacing: 14) {
                if !sound.imageUrl.isEmpty {
                    Image(sound.imageUrl)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray5))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "waveform")
                                .foregroundStyle(.secondary)
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(sound.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(sound.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                let isFav = store.favouriteAsmrSoundIds.contains(sound.id)
                Button {
                    let userId = userStore.currentUser?.id ?? DummyData.currentUser.id
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        store.toggleAsmrFavourite(soundId: sound.id, userId: userId)
                    }
                } label: {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundStyle(isFav ? Color.accentColor : Color.secondary.opacity(0.6))
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(height: 76)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SensorySootheView()
            .environment(CalmCentreStore.shared)
            .environment(UserStore())
    }
}
