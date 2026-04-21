//
//  SavedSpotsView.swift
//  RoamWild
//
//  List of every spot the user has hearted. Tap to open detail.
//

import SwiftUI

struct SavedSpotsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSpot: Spot?

    var body: some View {
        NavigationStack {
            Group {
                if savedSpots.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Saved spots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(item: $selectedSpot) { spot in
            SpotDetailView(spot: spot)
        }
    }

    private var savedSpots: [Spot] {
        appState.spots.filter { appState.savedSpotIDs.contains($0.id) }
    }

    private var list: some View {
        List {
            ForEach(savedSpots) { spot in
                Button {
                    selectedSpot = spot
                } label: {
                    row(spot)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: unsave)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Brand.canvas)
    }

    private func row(_ spot: Spot) -> some View {
        HStack(spacing: 12) {
            let c = spot.category.color
            ZStack {
                Color(red: c.r, green: c.g, blue: c.b).opacity(0.18)
                Text(spot.category.emoji).font(.system(size: 24))
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(spot.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Brand.night)
                Text(spot.location)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                HStack(spacing: 8) {
                    Text(spot.category.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Brand.ember)
                    Text(spot.type.label)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "heart.slash")
                .font(.system(size: 40))
                .foregroundColor(Brand.ember.opacity(0.6))
            Text("No saved spots yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Brand.night)
            Text("Tap the heart on any spot to save it here for quick access.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                dismiss()
            } label: {
                Text("Browse the map")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(Brand.ember)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.canvas)
    }

    private func unsave(at offsets: IndexSet) {
        let toRemove = offsets.map { savedSpots[$0] }
        for spot in toRemove {
            appState.toggleSaved(spot)
        }
    }
}

#Preview {
    SavedSpotsView().environmentObject(AppState())
}
