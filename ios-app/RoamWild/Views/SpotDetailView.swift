//
//  SpotDetailView.swift
//  RoamWild
//

import SwiftUI
import MapKit

struct SpotDetailView: View {
    let spot: Spot
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                banner
                VStack(alignment: .leading, spacing: 6) {
                    Text(spot.name)
                        .font(.system(size: 20, weight: .semibold))
                    Text(spot.location)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                badges
                stars

                if let desc = spot.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundColor(Color.black.opacity(0.7))
                        .lineSpacing(4)
                }

                if let why = spot.geologicalWhy, !why.isEmpty {
                    tipBox(icon: "🔬", label: "Why here", body: why,
                           bg: Brand.canvas, fg: Color.black.opacity(0.7))
                }
                if let tip = spot.insiderTip, !tip.isEmpty {
                    tipBox(icon: "💡", label: "Insider tip", body: tip,
                           bg: Color(red: 0.88, green: 0.96, blue: 0.93),
                           fg: Color(red: 0.03, green: 0.31, blue: 0.25))
                }

                actionButtons
                    .padding(.top, 8)
            }
            .padding(20)
        }
    }

    // MARK: - Pieces

    private var banner: some View {
        let c = spot.category.color
        return ZStack {
            Color(red: c.r, green: c.g, blue: c.b).opacity(0.15)
            Text(spot.category.emoji).font(.system(size: 56))
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var badges: some View {
        HStack(spacing: 6) {
            badge(label: spot.type.label,
                  fg: spot.type == .free ? Color(red: 0.03, green: 0.31, blue: 0.25) : Color(red: 0.09, green: 0.37, blue: 0.64),
                  bg: spot.type == .free ? Color(red: 0.88, green: 0.96, blue: 0.93) : Color(red: 0.9, green: 0.95, blue: 0.98))
            if spot.isKnownSpot {
                badge(label: "⭐ Known spot",
                      fg: Color(red: 0.52, green: 0.31, blue: 0.04),
                      bg: Color(red: 0.98, green: 0.93, blue: 0.85))
            }
            if let conf = spot.confidencePct {
                badge(label: "Confidence \(conf)%",
                      fg: conf >= 90 ? Color(red: 0.11, green: 0.62, blue: 0.46) : Color(red: 0.94, green: 0.62, blue: 0.15),
                      bg: Color.gray.opacity(0.08))
            }
        }
    }

    private func badge(label: String, fg: Color, bg: Color) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(fg)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var stars: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: Double(i) <= spot.rating.rounded() ? "star.fill" : "star")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.94, green: 0.62, blue: 0.15))
            }
            Text(String(format: "%.1f", spot.rating))
                .font(.system(size: 11))
                .foregroundColor(.gray)
            Text("(\(spot.reviewCount) reviews)")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
    }

    private func tipBox(icon: String, label: String, body: String, bg: Color, fg: Color) -> some View {
        Text("\(icon) \(label): \(body)")
            .font(.system(size: 11))
            .italic()
            .foregroundColor(fg)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button(action: openDirections) {
                Text("Get directions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Brand.ember)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                appState.toggleSaved(spot)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: appState.isSaved(spot) ? "heart.fill" : "heart")
                    Text(appState.isSaved(spot) ? "Saved" : "Save")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(appState.isSaved(spot) ? Brand.ember : Brand.night)
                .padding(.horizontal, 14).padding(.vertical, 11)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func openDirections() {
        let placemark = MKPlacemark(coordinate: spot.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = spot.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

#Preview {
    SpotDetailView(spot: Spot(
        id: "1", name: "Ballarat Goldfields", category: .gold,
        country: "AU", region: "Victoria",
        latitude: -37.56, longitude: 143.85,
        rating: 4.7, reviewCount: 124,
        description: "Historic goldfields — pan the creek bed at dawn for colour.",
        insiderTip: "Park by the old pump house and walk upstream 300m.",
        isKnownSpot: true, confidencePct: 95
    ))
    .environmentObject(AppState())
}
