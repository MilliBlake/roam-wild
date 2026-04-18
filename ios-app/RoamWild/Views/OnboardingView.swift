//
//  OnboardingView.swift
//  RoamWild
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var page: Int = 0

    private let slides: [OnboardSlide] = [
        .init(emoji: "🌍",
              title: "Welcome to Roam Wild",
              subtitle: "The ultimate outdoor adventure platform. Discover incredible spots for every activity — anywhere on earth."),
        .init(emoji: "💛",
              title: "Community Knowledge",
              subtitle: "Gold fossicking creeks, secret surf breaks, wild mushroom forests, hidden hot springs. Real spots from real adventurers."),
        .init(emoji: "📍",
              title: "Share Your Finds",
              subtitle: "Found an epic spot? Add it to the map and help the community. Together we're building the world's greatest outdoor database.")
    ]

    var body: some View {
        ZStack {
            Brand.night.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { idx in
                        slideView(slides[idx]).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(slides.indices, id: \.self) { i in
                            Capsule()
                                .fill(i == page ? Brand.ember : Color.white.opacity(0.2))
                                .frame(width: i == page ? 24 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: page)
                        }
                    }

                    Button(action: next) {
                        Text(page == slides.count - 1 ? "Let's go! →" : "Get Started")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: 320)
                            .padding(.vertical, 16)
                            .background(Brand.ember)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button("Skip intro") { finish() }
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.35))
                }
                .padding(32)
            }
        }
    }

    private func slideView(_ s: OnboardSlide) -> some View {
        VStack(spacing: 24) {
            Text(s.emoji).font(.system(size: 80))
            Text(s.title)
                .font(.custom("AvenirNext-Bold", size: 34))
                .kerning(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            Text(s.subtitle)
                .font(.system(size: 15))
                .foregroundColor(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 280)
        }
        .padding(.horizontal, 32)
    }

    private func next() {
        if page < slides.count - 1 {
            withAnimation(.easeInOut) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        withAnimation { appState.hasOnboarded = true }
    }
}

struct OnboardSlide {
    let emoji: String
    let title: String
    let subtitle: String
}

#Preview {
    OnboardingView().environmentObject(AppState())
}
