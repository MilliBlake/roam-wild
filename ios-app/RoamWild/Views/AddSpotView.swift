//
//  AddSpotView.swift
//  RoamWild
//
//  Live "Add Spot" form. Gated behind sign-in; POSTs to Supabase /rest/v1/spots
//  with approved=false so the row goes through review before appearing on the public map.
//

import SwiftUI
import CoreLocation

struct AddSpotView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var locator = OneShotLocator()

    @State private var name = ""
    @State private var region = ""
    @State private var country = ""
    @State private var category: SpotCategory = .hiking
    @State private var type: SpotType = .free
    @State private var description = ""
    @State private var insiderTip = ""

    @State private var latitudeText = ""
    @State private var longitudeText = ""

    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showAuth = false

    var body: some View {
        NavigationStack {
            if appState.isSignedIn {
                formView
            } else {
                signInGate
            }
        }
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
    }

    // MARK: - Form (signed in)

    private var formView: some View {
        Form {
            Section("Basics") {
                TextField("Spot name", text: $name)
                    .textInputAutocapitalization(.words)
                TextField("Region (e.g. Victoria)", text: $region)
                    .textInputAutocapitalization(.words)
                TextField("Country (e.g. AU)", text: $country)
                    .textInputAutocapitalization(.characters)
            }

            Section("Activity") {
                Picker("Category", selection: $category) {
                    ForEach(SpotCategory.allCases) { cat in
                        HStack {
                            Text(cat.emoji)
                            Text(cat.displayName)
                        }
                        .tag(cat)
                    }
                }
                Picker("Type", selection: $type) {
                    Text("Free").tag(SpotType.free)
                    Text("Paid").tag(SpotType.paid)
                }
                .pickerStyle(.segmented)
            }

            Section {
                HStack {
                    TextField("Latitude", text: $latitudeText)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Longitude", text: $longitudeText)
                        .keyboardType(.numbersAndPunctuation)
                }
                Button {
                    Task { await useMyLocation() }
                } label: {
                    HStack {
                        Image(systemName: locator.isWorking ? "location.fill" : "location")
                        Text(locator.isWorking ? "Finding your location..." : "Use my location")
                    }
                    .foregroundColor(Brand.ember)
                }
                .disabled(locator.isWorking)
                if let msg = locator.lastError {
                    Text(msg)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Location")
            } footer: {
                Text("Coordinates are how the spot gets pinned on the map. Drop a pin on Apple Maps and long-press to copy the lat/long if you need to.")
                    .font(.system(size: 11))
            }

            Section("Details") {
                TextField("Short description", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                TextField("Insider tip", text: $insiderTip, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if isSubmitting { ProgressView().tint(.white) }
                        Text(isSubmitting ? "Submitting..." : "Submit for review")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .listRowBackground(canSubmit ? Brand.ember : Color.gray.opacity(0.5))
                .disabled(!canSubmit || isSubmitting)

                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }

            Section {
                Text("Submitted spots are reviewed before they appear on the public map. Thanks for contributing!")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Add a spot")
        .alert("Thanks!", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your spot is queued for review. We'll email you once it's live.")
        }
    }

    // MARK: - Sign-in gate

    private var signInGate: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "lock.shield")
                .font(.system(size: 44))
                .foregroundColor(Brand.ember)
            Text("Sign in to add a spot")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Brand.night)
            Text("So we can credit you as the contributor, Roam Wild asks members to sign in before submitting spots.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showAuth = true
            } label: {
                Text("Sign in / Sign up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(Brand.ember)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Brand.canvas)
        .navigationTitle("Add a spot")
    }

    // MARK: - Actions

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(latitudeText) != nil &&
        Double(longitudeText) != nil
    }

    private func useMyLocation() async {
        let coord = await locator.requestOnce()
        if let coord {
            latitudeText = String(format: "%.5f", coord.latitude)
            longitudeText = String(format: "%.5f", coord.longitude)
        }
    }

    private func submit() async {
        errorMessage = nil
        guard let lat = Double(latitudeText), let lon = Double(longitudeText) else {
            errorMessage = "Enter a valid latitude and longitude."
            return
        }
        let draft = SpotDraft(
            name: name.trimmingCharacters(in: .whitespaces),
            region: region.trimmingCharacters(in: .whitespaces),
            country: country.trimmingCharacters(in: .whitespaces),
            category: category,
            type: type,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            insiderTip: insiderTip.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: lat,
            longitude: lon,
            submittedBy: nil
        )
        isSubmitting = true
        do {
            try await appState.submitSpot(draft)
            showSuccess = true
            resetForm()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    private func resetForm() {
        name = ""; region = ""; country = ""
        description = ""; insiderTip = ""
        category = .hiking; type = .free
        latitudeText = ""; longitudeText = ""
    }
}

// MARK: - One-shot CoreLocation helper

@MainActor
final class OneShotLocator: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isWorking = false
    @Published var lastError: String?

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestOnce() async -> CLLocationCoordinate2D? {
        if isWorking { return nil }
        isWorking = true
        lastError = nil

        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            lastError = "Location access is off. Enable it in Settings."
            isWorking = false
            return nil
        }

        return await withCheckedContinuation { cont in
            self.continuation = cont
            self.manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            let coord = locations.last?.coordinate
            self.continuation?.resume(returning: coord)
            self.continuation = nil
            self.isWorking = false
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error.localizedDescription
            self.continuation?.resume(returning: nil)
            self.continuation = nil
            self.isWorking = false
        }
    }
}

#Preview {
    AddSpotView().environmentObject(AppState())
}
