//
//  RootView.swift
//  RoamWild
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.hasOnboarded {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .task {
            if appState.spots.isEmpty {
                await appState.loadSpots()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selection: Tab = .home

    enum Tab { case home, map, add }

    var body: some View {
        TabView(selection: $selection) {
            HomeView(onOpenMap: { cat in
                appState.activeCategoryFilter = cat
                selection = .map
            })
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(Tab.home)

            MapScreenView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(Tab.map)

            AddSpotView()
                .tabItem {
                    Label("Add Spot", systemImage: "plus.circle.fill")
                }
                .tag(Tab.add)
        }
        .tint(Brand.ember)
    }
}

#Preview {
    RootView().environmentObject(AppState())
}
