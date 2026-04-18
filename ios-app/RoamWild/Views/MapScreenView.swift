//
//  MapScreenView.swift
//  RoamWild
//
//  Native MapKit replacement for the Leaflet map in the web POC.
//

import SwiftUI
import MapKit

struct MapScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -27, longitude: 134),
            span: MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 50)
        )
    )
    @State private var selectedSpot: Spot?
    @State private var showAccount = false

    var body: some View {
        ZStack(alignment: .top) {
            mapLayer
            VStack(spacing: 0) {
                topBar
                statsBar
                filterChips
                Spacer()
            }
        }
        .sheet(item: $selectedSpot) { spot in
            SpotDetailView(spot: spot)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAccount) {
            if appState.isSignedIn {
                AccountView()
            } else {
                AuthView()
            }
        }
        .overlay(alignment: .center) {
            if appState.isLoading && appState.spots.isEmpty {
                loadingOverlay
            } else if let err = appState.loadError, appState.spots.isEmpty {
                errorOverlay(err)
            }
        }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $cameraPosition, selection: Binding(
            get: { selectedSpot?.id },
            set: { newID in
                if let id = newID {
                    selectedSpot = appState.spots.first(where: { $0.id == id })
                } else {
                    selectedSpot = nil
                }
            }
        )) {
            ForEach(appState.filteredSpots) { spot in
                Annotation(spot.name, coordinate: spot.coordinate) {
                    pinView(for: spot)
                        .onTapGesture { selectedSpot = spot }
                }
                .tag(spot.id)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea()
    }

    private func pinView(for spot: Spot) -> some View {
        ZStack {
            let c = spot.category.color
            let color = Color(red: c.r, green: c.g, blue: c.b)
            Circle()
                .fill(color)
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
            Text(spot.category.emoji)
                .font(.system(size: 14))
            if spot.isKnownSpot {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .offset(x: 12, y: -12)
            }
        }
    }

    // MARK: - Overlays

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Brand.ember)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "location.north.line.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
                Text("ROAM WILD")
                    .font(.system(size: 16, weight: .heavy))
                    .kerning(0.8)
                    .foregroundColor(Brand.night)
            }

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
                TextField("Search spots...", text: $appState.searchText)
                    .font(.system(size: 13))
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Brand.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )

            Button {
                showAccount = true
            } label: {
                if appState.isSignedIn {
                    Circle()
                        .fill(Brand.ember)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(mapProfileInitial)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        )
                } else {
                    Text("Sign In")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Brand.ember)
                        .clipShape(Capsule())
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.shadow(color: .black.opacity(0.05), radius: 4, y: 2))
    }

    private var mapProfileInitial: String {
        if let n = appState.username, let first = n.first {
            return String(first).uppercased()
        }
        return "?"
    }

    private var statsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                stat("\(appState.spots.count)", "live spots")
                stat("\(appState.countsByCategory[.gold] ?? 0)", "💛 gold")
                stat("\(appState.countsByCategory[.surfing] ?? 0)", "🏄 surf")
                stat("\(appState.countsByCategory[.hiking] ?? 0)", "🥾 hiking")
                stat("\(appState.countsByCategory[.mtb] ?? 0)", "🚵 MTB")
                stat("\(appState.countsByCategory[.skydiving] ?? 0)", "🪂 skydive")
                stat("\(appState.countsByCategory[.wellness] ?? 0)", "🧘 wellness")
                stat("\(appState.countsByCategory[.foraging] ?? 0)", "🍄 foraging")
                stat("\(appState.countsByCategory[.lookout] ?? 0)", "🏔️ lookouts")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .background(Brand.night)
    }

    private func stat(_ num: String, _ label: String) -> some View {
        HStack(spacing: 6) {
            Text(num)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Brand.ember)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color.white.opacity(0.5))
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip(label: "All",
                     isActive: appState.activeCategoryFilter == nil && !appState.knownOnly && !appState.freeOnly) {
                    appState.activeCategoryFilter = nil
                    appState.knownOnly = false
                    appState.freeOnly = false
                }
                ForEach(SpotCategory.allCases) { cat in
                    chip(label: "\(cat.emoji) \(cat.displayName)",
                         isActive: appState.activeCategoryFilter == cat) {
                        appState.activeCategoryFilter = cat
                    }
                }
                chip(label: "⭐ Known",
                     isActive: appState.knownOnly,
                     isWarm: true) {
                    appState.knownOnly.toggle()
                }
                chip(label: "🆓 Free only",
                     isActive: appState.freeOnly) {
                    appState.freeOnly.toggle()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(Color.white)
    }

    private func chip(label: String, isActive: Bool, isWarm: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? (isWarm ? Color(red: 0.39, green: 0.22, blue: 0.02) : Brand.emberDark) : Color.black.opacity(0.55))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isActive ? (isWarm ? Color(red: 0.98, green: 0.93, blue: 0.85) : Brand.emberLight) : Color.white)
                .overlay(
                    Capsule().stroke(isActive ? Brand.ember : Color.black.opacity(0.1), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var loadingOverlay: some View {
        VStack(spacing: 12) {
            Text("ROAM WILD")
                .font(.system(size: 42, weight: .heavy))
                .kerning(2)
                .foregroundColor(Brand.ember)
            ProgressView().tint(Brand.ember)
            Text("Loading spots...")
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .padding(40)
        .background(Brand.canvas.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func errorOverlay(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Text("⚠️ Could not load spots")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Brand.emberDark)
            Text(msg)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("Try again") {
                Task { await appState.loadSpots() }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Brand.ember)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 10)
        .padding(40)
    }
}

#Preview {
    MapScreenView().environmentObject(AppState())
}
