//
//  HomeView.swift
//  RoamWild
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    var onOpenMap: (SpotCategory?) -> Void
    @State private var showAccount = false

    private let featured: [FeaturedSpot] = [
        .init(title: "Ballarat Goldfields", loc: "Victoria, Australia", emoji: "💛",
              badge: "⭐ Known spot", tint: Color(red: 0.10, green: 0.22, blue: 0.16),
              cat: .gold),
        .init(title: "Pipeline", loc: "North Shore, Hawaii", emoji: "🏄",
              badge: "🔥 Legendary", tint: Color(red: 0.04, green: 0.16, blue: 0.22),
              cat: .surfing),
        .init(title: "Everest Base Camp", loc: "Khumbu, Nepal", emoji: "🥾",
              badge: "🏔️ Bucket list", tint: Color(red: 0.16, green: 0.10, blue: 0.22),
              cat: .hiking),
        .init(title: "Blue Lagoon", loc: "Iceland", emoji: "🧘",
              badge: "💎 Premium", tint: Color(red: 0.22, green: 0.10, blue: 0.10),
              cat: .wellness),
        .init(title: "Skydive Mission Beach", loc: "Far North QLD", emoji: "🪂",
              badge: "⚡ Epic views", tint: Color(red: 0.10, green: 0.16, blue: 0.10),
              cat: .skydiving)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                if let err = appState.loadError {
                    errorBanner(err)
                }
                contentSection
            }
        }
        .refreshable {
            await appState.loadSpots()
        }
        .background(Brand.canvas)
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showAccount) {
            if appState.isSignedIn {
                AccountView()
            } else {
                AuthView()
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Brand.ember)
            VStack(alignment: .leading, spacing: 2) {
                Text("Couldn't load spots")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Brand.night)
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Button("Retry") {
                Task { await appState.loadSpots() }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Brand.ember)
        }
        .padding(12)
        .background(Color(red: 0.99, green: 0.92, blue: 0.85))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Brand.ember.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Sections

    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            Brand.night

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 10) {
                        RoamWildLogoBadge(size: 36)
                        Text("Roam Wild")
                            .font(.system(size: 22, weight: .heavy, design: .default))
                            .kerning(1.2)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button {
                        showAccount = true
                    } label: {
                        Circle()
                            .fill(Brand.ember)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Group {
                                    if let letter = profileInitial {
                                        Text(letter)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(appState.isSignedIn ? "Account" : "Sign in")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.5))
                    Text("\((appState.username ?? "Adventurer")) 👋")
                        .font(.system(size: 28, weight: .heavy))
                        .kerning(1)
                        .foregroundColor(.white)
                }

                Button {
                    onOpenMap(nil)
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.white.opacity(0.4))
                        Text("Search spots, activities, countries...")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.4))
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 70)
            .padding(.bottom, 48)

            Brand.canvas
                .frame(height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .offset(y: 20)
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            statsRow
            featuredSection
            categoriesSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 60)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(value: "\(appState.spots.count)", label: "Total spots")
            statCard(value: "\(SpotCategory.allCases.count)", label: "Categories")
            statCard(value: "\(Set(appState.spots.compactMap { $0.country }).count)", label: "Countries")
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(Brand.ember)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color.black.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Featured spots")
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Button("See all →") { onOpenMap(nil) }
                    .font(.system(size: 12))
                    .foregroundColor(Brand.ember)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(featured) { f in
                        featuredCard(f)
                            .onTapGesture { onOpenMap(f.cat) }
                    }
                }
            }
        }
    }

    private func featuredCard(_ f: FeaturedSpot) -> some View {
        ZStack(alignment: .bottomLeading) {
            f.tint
            Text(f.emoji).font(.system(size: 50))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .bottom, endPoint: .center
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(f.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(f.loc)
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.7))
            }
            .padding(12)

            Text(f.badge)
                .font(.system(size: 9))
                .foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .frame(width: 200, height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Explore by activity")
                .font(.system(size: 15, weight: .medium))

            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(SpotCategory.allCases) { cat in
                    Button { onOpenMap(cat) } label: {
                        VStack(spacing: 6) {
                            Text(cat.emoji).font(.system(size: 24))
                            Text(cat.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.black.opacity(0.6))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var profileInitial: String? {
        if let n = appState.username, let first = n.first {
            return String(first).uppercased()
        }
        return nil
    }
}

struct FeaturedSpot: Identifiable {
    let id = UUID()
    let title: String
    let loc: String
    let emoji: String
    let badge: String
    let tint: Color
    let cat: SpotCategory
}

#Preview {
    HomeView(onOpenMap: { _ in }).environmentObject(AppState())
}
