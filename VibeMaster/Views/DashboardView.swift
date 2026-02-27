//
//  DashboardView.swift
//  VibeMaster
//

import SwiftUI

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

    var body: some View {
        List {
            if !isSearching {
                Section("Mes Blind Tests") {
                    if favoritePlaylists.isEmpty {
                        Text("Ajoutez des playlists en favori pour les retrouver ici.")
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
                }
                Section("Top playlists") {
                    if isLoadingChart {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if let msg = errorMessage {
                        Text(msg)
                        Button("Réessayer") { loadChart() }
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
                            }                             onTap: { selectPlaylist(id: item.id) }
                        }
                    }
                }
                
            } else {
                Section("Résultats") {
                    if isLoadingSearch {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if searchResults.isEmpty {
                        Text("Aucun résultat")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(searchResults, id: \.id) { item in
                            PlaylistRowView(item: item, isFavorite: FavoritesManager.shared.contains(id: item.id), onAdd: {
                                FavoritesManager.shared.add(item)
                                HapticManager.light()
                            }, onRemove: { FavoritesManager.shared.remove(id: item.id); loadFavorites() }, onTap: { selectPlaylist(id: item.id) })
                        }
                    }
                }
            }
        }
        .navigationDestination(item: $setupItem) { item in
            SetupView(path: $path, initialTracks: item.tracks, onCancel: { setupItem = nil })
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .navigationTitle("Accueil")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Rechercher des playlists")
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
            } catch {
                await MainActor.run {
                    errorMessage = "Impossible de charger les playlists. Vérifiez votre connexion."
                    isLoadingChart = false
                }
            }
        }
    }

    private func loadFavorites() {
        favoritePlaylists = FavoritesManager.shared.load()
    }

    private func runSearch() async {
        await MainActor.run { isLoadingSearch = true }
        do {
            let list = try await DeezerAPIService.shared.searchPlaylists(query: searchText.trimmingCharacters(in: .whitespacesAndNewlines))
            await MainActor.run {
                searchResults = list.filter { ($0.nb_tracks ?? 0) > 0 }
                isLoadingSearch = false
            }
        } catch {
            await MainActor.run {
                searchResults = []
                isLoadingSearch = false
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
            } catch {
                await MainActor.run { errorMessage = "Impossible de charger les titres." }
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
        Button(action: onTap) {
            HStack {
                AsyncImage(url: URL(string: item.picture_medium ?? "")) { image in image.resizable() }
                    placeholder: { Color.gray.opacity(0.3) }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(1)
                    if let n = item.nb_tracks {
                        Text("\(n) titres")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    if isFavorite { onRemove() } else { onAdd() }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                }
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
