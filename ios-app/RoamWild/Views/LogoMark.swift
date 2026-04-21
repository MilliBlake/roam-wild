//
//  LogoMark.swift
//  RoamWild
//
//  Native SwiftUI port of the brand mark used in the web POC
//  (index.html / home.html / auth.html / add_spot.html).
//
//  Original SVG (22×22 viewBox):
//    path: M3 16 Q8 8 11 12 Q14 8 19 4     (wavy trail, 2.2 stroke, round caps)
//    circle(19, 4, r=2.5, fill=white)      (destination dot)
//    circle(3, 16, r=1.8, fill=white, opacity=0.6)   (origin dot)
//

import SwiftUI

/// The Roam Wild trail-with-endpoints glyph. Draws at any size, matches the
/// original SVG geometry exactly. Usage:
///     RoamWildLogoMark(stroke: .white)
///         .frame(width: 20, height: 20)
struct RoamWildLogoMark: View {
    /// Color of the trail stroke and destination dot. Origin dot uses the same
    /// color at 60% opacity (matches the POC).
    var stroke: Color = .white

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) / 22.0  // scale from 22pt design grid
            ZStack {
                // Trail path
                Path { p in
                    p.move(to: CGPoint(x: 3 * s, y: 16 * s))
                    p.addQuadCurve(
                        to: CGPoint(x: 11 * s, y: 12 * s),
                        control: CGPoint(x: 8 * s, y: 8 * s)
                    )
                    p.addQuadCurve(
                        to: CGPoint(x: 19 * s, y: 4 * s),
                        control: CGPoint(x: 14 * s, y: 8 * s)
                    )
                }
                .stroke(stroke, style: StrokeStyle(lineWidth: 2.2 * s, lineCap: .round, lineJoin: .round))

                // Destination dot (upper right)
                Circle()
                    .fill(stroke)
                    .frame(width: 5 * s, height: 5 * s)
                    .position(x: 19 * s, y: 4 * s)

                // Origin dot (lower left, softer)
                Circle()
                    .fill(stroke.opacity(0.6))
                    .frame(width: 3.6 * s, height: 3.6 * s)
                    .position(x: 3 * s, y: 16 * s)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The ember-orange rounded badge that houses the mark in the header. Matches
/// `.logo-icon` in the web POC (36pt ember square, 10pt radius).
struct RoamWildLogoBadge: View {
    var size: CGFloat = 36
    var cornerRadius: CGFloat = 10

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Brand.ember)
            .frame(width: size, height: size)
            .overlay(
                RoamWildLogoMark(stroke: .white)
                    .padding(size * 0.18)     // matches the POC's inner padding
            )
    }
}

#Preview {
    VStack(spacing: 24) {
        RoamWildLogoBadge(size: 36)
        RoamWildLogoBadge(size: 52, cornerRadius: 14)
        RoamWildLogoMark(stroke: .black)
            .frame(width: 80, height: 80)
    }
    .padding(40)
    .background(Color.gray.opacity(0.1))
}
