//
//  DashboardView.swift
//  VibeMaster
//

import SwiftUI
import VibeMasterCore

struct DashboardView: View {
    @Binding var path: [AppDestination]
    @State private var searchText = ""
    @State private var chartPlaylists: [DeezerPlaylistItem] = []
    @State private var searchResults: [DeezerPlaylistItem] = []
    @State private var favoritePlaylists: [DeezerPlaylistItem] = []
    @State private var isSearching = false
    @State private var isLoadingChart = true
    @State private var isLoadingSearch = false
    @State private var errorMessage: String?
    @State private var setupItem: SetupItem?
    @State private var searchTask: Task<Void, Never>?

    private struct SetupItem: Identifiable, Hashable {
        let id = UUID()
        let tracks: [Track]
    }

    private let rowCornerRadius: CGFloat = 12

    var body: some View {
        ZStack {
            // Dark glass-style background (matches screenshot)
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.14),
                    Color(red: 0.05, green: 0.05, blue: 0.10),
                    Color(red: 0.02, green: 0.02, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            List {
                if !isSearching {
                    favoritesSection
                    topPlaylistsSection
                } else {
                    searchResultsSection
                }
                Section {
                    DeezerAttributionView(forLightBackground: false)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(glassRowBackground)
        }
        .navigationDestination(item: $setupItem) { item in
            SetupView(path: $path, initialTracks: item.tracks, onCancel: { setupItem = nil })
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 56) }
        .preferredColorScheme(.dark)
        .navigationTitle(AppStrings.Dashboard.home)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(AppStrings.Dashboard.home)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
            }
        }
        .searchable(text: $searchText, prompt: AppStrings.Dashboard.searchPlaylistsPrompt)
        .onChange(of: searchText) { _, newValue in
            let t = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.count >= 3 {
                isSearching = true
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    guard !Task.isCancelled else { return }
                    await runSearch()
                }
            } else {
                isSearching = false
                searchResults = []
            }
        }
        .onSubmit(of: .search) {
            Task { await runSearch() }
        }
        .onAppear {
            loadChart()
            loadFavorites()
        }
    }

    private var glassRowBackground: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: rowCornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Section subviews

    private var favoritesSection: some View {
        Section {
            if favoritePlaylists.isEmpty {
                Text(AppStrings.Dashboard.addFavoritesHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(favoritePlaylists, id: \.id) { item in
                    PlaylistRowView(item: item, isFavorite: true, onAdd: {}, onRemove: {
                        FavoritesManager.shared.remove(id: item.id)
                        HapticManager.light()
                        loadFavorites()
                    }, onTap: { selectPlaylist(id: item.id) })
                }
            }
        } header: {
            Text(AppStrings.Dashboard.myBlindTests)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .textCase(.uppercase)
        }
    }

    private var topPlaylistsSection: some View {
        Section {
            if isLoadingChart {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let msg = errorMessage {
                Text(msg)
                    .foregroundStyle(.secondary)
                Button(AppStrings.Common.retry) { loadChart() }
                    .buttonStyle(.bordered)
            } else {
                ForEach(chartPlaylists.prefix(10), id: \.id) { item in
                    PlaylistRowView(item: item, isFavorite: FavoritesManager.shared.contains(id: item.id)) {
                        FavoritesManager.shared.add(item)
                        HapticManager.light()
                        loadFavorites()
                    } onRemove: {
                        FavoritesManager.shared.remove(id: item.id)
                        HapticManager.light()
                        loadFavorites()
                    } onTap: { selectPlaylist(id: item.id) }
                }
            }
        } header: {
            Text(AppStrings.Dashboard.topPlaylists)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .textCase(.uppercase)
        }
    }

    private var searchResultsSection: some View {
        Section {
            if isLoadingSearch {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let msg = errorMessage {
                Text(msg)
                    .foregroundStyle(.secondary)
                Button(AppStrings.Common.retry) {
                    errorMessage = nil
                    Task { await runSearch() }
                }
                .buttonStyle(.bordered)
            } else if searchResults.isEmpty {
                Text(AppStrings.Dashboard.noResults)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(searchResults, id: \.id) { item in
                    PlaylistRowView(item: item, isFavorite: FavoritesManager.shared.contains(id: item.id), onAdd: {
                        FavoritesManager.shared.add(item)
                        HapticManager.light()
                    }, onRemove: { FavoritesManager.shared.remove(id: item.id); loadFavorites() }, onTap: { selectPlaylist(id: item.id) })
                }
            }
        } header: {
            Text(AppStrings.Dashboard.results)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .textCase(.uppercase)
        }
    }

    private static var quotaExceededMessage: String { AppStrings.Errors.quotaExceeded }

    private func loadChart() {
        isLoadingChart = true
        errorMessage = nil
        Task {
            do {
                let list = try await DeezerAPIService.shared.chartPlaylists()
                await MainActor.run {
                    chartPlaylists = list
                    isLoadingChart = false
                    errorMessage = nil
                }
            } catch let err as DeezerAPIError {
                await MainActor.run {
                    errorMessage = err == .quotaExceeded
                        ? Self.quotaExceededMessage
                        : AppStrings.Errors.loadPlaylists
                    isLoadingChart = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = AppStrings.Errors.loadPlaylists
                    isLoadingChart = false
                }
            }
        }
    }

    private func loadFavorites() {
        favoritePlaylists = FavoritesManager.shared.load()
    }

    private func runSearch() async {
        await MainActor.run { isLoadingSearch = true; errorMessage = nil }
        do {
            let list = try await DeezerAPIService.shared.searchPlaylists(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
            await MainActor.run {
                searchResults = list.filter { ($0.nb_tracks ?? 0) > 0 }
                isLoadingSearch = false
                errorMessage = nil
            }
        } catch let err as DeezerAPIError {
            await MainActor.run {
                searchResults = []
                isLoadingSearch = false
                errorMessage = err == .quotaExceeded ? Self.quotaExceededMessage : AppStrings.Errors.loadResults
            }
        } catch {
            await MainActor.run {
                searchResults = []
                isLoadingSearch = false
                errorMessage = AppStrings.Errors.loadResults
            }
        }
    }

    private func selectPlaylist(id: Int) {
        Task {
            do {
                let tracks = try await DeezerAPIService.shared.playlistDetail(id: id)
                await MainActor.run {
                    setupItem = SetupItem(tracks: tracks)
                }
            } catch let err as DeezerAPIError {
                await MainActor.run {
                    errorMessage = err == .quotaExceeded ? Self.quotaExceededMessage : AppStrings.Errors.loadTracks
                }
            } catch {
                await MainActor.run { errorMessage = AppStrings.Errors.loadTracks }
            }
        }
    }
}

struct PlaylistRowView: View {
    let item: DeezerPlaylistItem
    let isFavorite: Bool
    var onAdd: () -> Void = {}
    var onRemove: () -> Void = {}
    var onTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.picture_medium ?? "")) { image in image.resizable() }
                placeholder: { Color.gray.opacity(0.2) }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let n = item.nb_tracks {
                    Text(AppStrings.Dashboard.trackCount(n))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                if isFavorite { onRemove() } else { onAdd() }
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.body)
                    .foregroundStyle(isFavorite ? .red : .secondary)
            }
            .buttonStyle(.plain)
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Deezer attribution (required by Deezer API terms: https://developers.deezer.com/guidelines/logo)
struct DeezerAttributionView: View {
    private static let deezerURL = URL(string: "https://www.deezer.com")
    /// Use light text on dark (e.g. splash) or dark text on light (e.g. dashboard).
    var forLightBackground: Bool = false

    var body: some View {
        Group {
            if let url = Self.deezerURL {
                Link(destination: url) { DeezerAttributionBadge(forLightBackground: forLightBackground) }
            } else {
                DeezerAttributionBadge(forLightBackground: forLightBackground)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityLabel(AppStrings.Splash.poweredByDeezer)
        .accessibilityHint(AppStrings.Dashboard.deezerAccessibilityHint)
    }
}

/// Compact Deezer logo + "Powered by Deezer" badge, reused on splash and dashboard.
/// Add the official Deezer logo to Assets.xcassets/DeezerLogo.imageset to display it.
struct DeezerAttributionBadge: View {
    var forLightBackground: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            if UIImage(named: "DeezerLogo") != nil {
                Image("DeezerLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                    .accessibilityHidden(true)
            }
            Text(AppStrings.Splash.poweredByDeezer)
                .font(.caption2)
                .foregroundStyle(forLightBackground ? Color.secondary : Color.white)
        }
    }
}

// MARK: - Previews

#Preview("DashboardView") {
    NavigationStack {
        DashboardView(path: .constant([]))
    }
}

#Preview("PlaylistRowView") {
    let item = DeezerPlaylistItem(id: 1, title: "Preview Playlist", picture_medium: nil, nb_tracks: 10)
    return PlaylistRowView(item: item, isFavorite: false, onAdd: {}, onRemove: {}, onTap: {})
}

#Preview("DeezerAttributionView") {
    DeezerAttributionView()
}
