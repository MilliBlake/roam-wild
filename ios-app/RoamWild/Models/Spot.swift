//
//  Spot.swift
//  RoamWild
//
//  Data model that mirrors the `spots` table consumed by the web POC.
//

import Foundation
import CoreLocation

struct Spot: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let category: SpotCategory
    let country: String?
    let region: String?
    let latitude: Double
    let longitude: Double
    let type: SpotType
    let rating: Double
    let reviewCount: Int
    let description: String?
    let geologicalWhy: String?
    let insiderTip: String?
    let isKnownSpot: Bool
    let confidencePct: Int?
    let knownTag: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: String {
        [region, country].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: ", ")
    }

    // MARK: - JSON decoding (Supabase REST returns snake_case)
    enum CodingKeys: String, CodingKey {
        case id, name, category, country, region, latitude, longitude
        case type, rating, description
        case reviewCount = "review_count"
        case geologicalWhy = "geological_why"
        case insiderTip = "insider_tip"
        case isKnownSpot = "is_known_spot"
        case confidencePct = "confidence_pct"
        case knownTag = "known_tag"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // id can come back as either UUID-string or integer; coerce to String.
        if let s = try? c.decode(String.self, forKey: .id) {
            id = s
        } else if let n = try? c.decode(Int.self, forKey: .id) {
            id = String(n)
        } else {
            id = UUID().uuidString
        }
        name = (try? c.decode(String.self, forKey: .name)) ?? "Unnamed spot"
        let rawCat = (try? c.decode(String.self, forKey: .category)) ?? "camping"
        category = SpotCategory(rawValue: rawCat.lowercased()) ?? .camping
        country = try? c.decode(String.self, forKey: .country)
        region = try? c.decode(String.self, forKey: .region)

        // Latitude / longitude may arrive as Double, String, or numeric — be defensive.
        latitude = Spot.decodeDouble(c, key: .latitude) ?? 0
        longitude = Spot.decodeDouble(c, key: .longitude) ?? 0

        let rawType = (try? c.decode(String.self, forKey: .type)) ?? "free"
        type = SpotType(rawValue: rawType.lowercased()) ?? .free

        rating = Spot.decodeDouble(c, key: .rating) ?? 4.5
        reviewCount = (try? c.decode(Int.self, forKey: .reviewCount)) ?? 0
        description = try? c.decode(String.self, forKey: .description)
        geologicalWhy = try? c.decode(String.self, forKey: .geologicalWhy)
        insiderTip = try? c.decode(String.self, forKey: .insiderTip)
        isKnownSpot = (try? c.decode(Bool.self, forKey: .isKnownSpot)) ?? false
        confidencePct = try? c.decode(Int.self, forKey: .confidencePct)
        knownTag = try? c.decode(String.self, forKey: .knownTag)
    }

    /// Designated init used for sample data and previews.
    init(id: String,
         name: String,
         category: SpotCategory,
         country: String?,
         region: String?,
         latitude: Double,
         longitude: Double,
         type: SpotType = .free,
         rating: Double = 4.5,
         reviewCount: Int = 0,
         description: String? = nil,
         geologicalWhy: String? = nil,
         insiderTip: String? = nil,
         isKnownSpot: Bool = false,
         confidencePct: Int? = nil,
         knownTag: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.country = country
        self.region = region
        self.latitude = latitude
        self.longitude = longitude
        self.type = type
        self.rating = rating
        self.reviewCount = reviewCount
        self.description = description
        self.geologicalWhy = geologicalWhy
        self.insiderTip = insiderTip
        self.isKnownSpot = isKnownSpot
        self.confidencePct = confidencePct
        self.knownTag = knownTag
    }

    private static func decodeDouble(_ c: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Double? {
        if let d = try? c.decode(Double.self, forKey: key) { return d }
        if let s = try? c.decode(String.self, forKey: key), let d = Double(s) { return d }
        if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
        return nil
    }
}

enum SpotType: String, Codable {
    case free, paid

    var label: String { self == .free ? "Free" : "Paid" }
}

/// All 19 categories from the web POC, in the same order shown in the filter bar.
enum SpotCategory: String, CaseIterable, Identifiable, Codable {
    case gold, fossicking, fishing, mtb, snowboard, hiking, climbing, kayak
    case surfing, skydiving, basejump, discgolf
    case fourwd = "4wd"
    case camping, swimming, lookout, wellness, foraging, gym

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gold: return "Gold"
        case .fossicking: return "Fossicking"
        case .fishing: return "Fishing"
        case .mtb: return "MTB"
        case .snowboard: return "Snow"
        case .hiking: return "Hiking"
        case .climbing: return "Climbing"
        case .kayak: return "Kayak"
        case .surfing: return "Surfing"
        case .skydiving: return "Skydiving"
        case .basejump: return "BASE Jump"
        case .discgolf: return "Disc Golf"
        case .fourwd: return "4WD"
        case .camping: return "Camping"
        case .swimming: return "Swimming"
        case .lookout: return "Lookouts"
        case .wellness: return "Wellness"
        case .foraging: return "Foraging"
        case .gym: return "Gyms"
        }
    }

    var emoji: String {
        switch self {
        case .gold: return "💛"
        case .fossicking: return "💎"
        case .fishing: return "🎣"
        case .mtb: return "🚵"
        case .snowboard: return "🏂"
        case .hiking: return "🥾"
        case .climbing: return "🧗"
        case .kayak: return "🛶"
        case .surfing: return "🏄"
        case .skydiving: return "🪂"
        case .basejump: return "🦅"
        case .discgolf: return "🥏"
        case .fourwd: return "🚙"
        case .camping: return "⛺"
        case .swimming: return "🏊"
        case .lookout: return "🏔️"
        case .wellness: return "🧘"
        case .foraging: return "🍄"
        case .gym: return "💪"
        }
    }

    /// SwiftUI Color matching CAT_COLOR in the web POC.
    var color: (r: Double, g: Double, b: Double) {
        switch self {
        case .camping: return (0xE8/255, 0x53/255, 0x1A/255)
        case .fishing, .gym: return (0x18/255, 0x5F/255, 0xA5/255)
        case .fossicking, .snowboard, .climbing: return (0x7F/255, 0x77/255, 0xDD/255)
        case .gold, .fourwd: return (0xBA/255, 0x75/255, 0x17/255)
        case .discgolf, .wellness: return (0xD4/255, 0x53/255, 0x7E/255)
        case .mtb, .hiking: return (0x4E/255, 0x9A/255, 0x6A/255)
        case .kayak, .surfing: return (0x37/255, 0x8A/255, 0xDD/255)
        case .swimming: return (0x5D/255, 0xCA/255, 0xA5/255)
        case .skydiving, .basejump: return (0xE2/255, 0x4B/255, 0x4A/255)
        case .lookout: return (0xEF/255, 0x9F/255, 0x27/255)
        case .foraging: return (0x63/255, 0x99/255, 0x22/255)
        }
    }
}
