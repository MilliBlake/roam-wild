//
//  PrivacyPolicyView.swift
//  RoamWild
//
//  In-app privacy policy. Mirrors the standalone HTML hosted at roamwild.app/privacy.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Roam Wild treats your data with the same care we'd want for our own. Here's exactly what we collect and why.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    section("What we collect",
                            "Email address and a chosen username when you sign up. Optional: your favourite activity. When you submit a spot or use 'Use my location', we collect the latitude and longitude you choose to share.")

                    section("How we use it",
                            "To show you relevant adventure spots, attribute submissions to you, and email account-related notices. We don't sell or share your data with advertisers.")

                    section("Where it's stored",
                            "On Supabase (a hosted Postgres provider) under our project. Data is encrypted in transit (HTTPS) and at rest.")

                    section("Location",
                            "Location is requested only when you tap 'Use my location' on the Add Spot form. We don't track you in the background. Coordinates are stored as part of the spot you submit.")

                    section("Saved spots",
                            "Your saved-spots list is stored locally on your device by default. Deleting the app removes it.")

                    section("Account deletion",
                            "Tap 'Delete Account' on the Account screen. This signs you out immediately and queues your profile, submissions, and saved data for permanent deletion within 30 days.")

                    section("Children",
                            "Roam Wild is intended for users 13 and over. We don't knowingly collect data from children under 13.")

                    section("Contact",
                            "Questions, requests, or anything else: hello@roamwild.app")

                    Text("Last updated: April 2026")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .padding(.top, 12)
                }
                .padding(20)
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func section(_ heading: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(heading)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Brand.night)
            Text(body)
                .font(.system(size: 13))
                .foregroundColor(Color.black.opacity(0.75))
                .lineSpacing(3)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
