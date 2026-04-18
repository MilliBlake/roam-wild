//
//  RoamWildApp.swift
//  RoamWild
//
//  Roam Wild — Go Further
//  V1 POC iOS app
//

import SwiftUI

@main
struct RoamWildApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}

/// Brand colors pulled directly from the web POC design tokens.
enum Brand {
    static let ember = Color(red: 0xE8 / 255, green: 0x53 / 255, blue: 0x1A / 255)
    static let emberDark = Color(red: 0xC4 / 255, green: 0x3D / 255, blue: 0x0E / 255)
    static let emberLight = Color(red: 0xFB / 255, green: 0xE9 / 255, blue: 0xE2 / 255)
    static let night = Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x18 / 255)
    static let forest = Color(red: 0x2E / 255, green: 0x4A / 255, blue: 0x35 / 255)
    static let trail = Color(red: 0x4E / 255, green: 0x9A / 255, blue: 0x6A / 255)
    static let sand = Color(red: 0xF5 / 255, green: 0xED / 255, blue: 0xD8 / 255)
    static let canvas = Color(red: 0xF9 / 255, green: 0xF7 / 255, blue: 0xF3 / 255)
}
