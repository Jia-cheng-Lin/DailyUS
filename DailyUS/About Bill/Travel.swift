//
//  Travel.swift
//  AboutMe
//
//  Created by 林嘉誠 on 2025/9/26.
//

import Foundation
import SwiftUI
import MapKit

extension CLLocationCoordinate2D {
    static let vancouver = CLLocationCoordinate2D(latitude: 49.2755681, longitude: -123.1136457)
    static let busan = CLLocationCoordinate2D(latitude: 35.1689766, longitude: 129.1360411)
    static let chiba = CLLocationCoordinate2D(latitude: 35.6476856, longitude: 140.0329537)
    static let bangkok = CLLocationCoordinate2D(latitude: 13.7303558, longitude: 100.5657949)
}

struct Travel: View {
    // 計算同時容納兩個標記的可視區域
    private var fitRegion: MKCoordinateRegion {
        let coords = [CLLocationCoordinate2D.vancouver, .busan]
        let minLat = coords.map { $0.latitude }.min() ?? 0
        let maxLat = coords.map { $0.latitude }.max() ?? 0
        let minLon = coords.map { $0.longitude }.min() ?? 0
        let maxLon = coords.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        // 稍微放大邊界，避免貼邊
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.5, (maxLat - minLat) * 1.8),
            longitudeDelta: max(0.5, (maxLon - minLon) * 1.8)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        Map{
//            Marker("JW Mariott Parq, Vancounver, Canada", coordinate: .vancouver)
            Annotation("""
                    IEEE SENSORS 2025
                    2025/10/19-10/22
                    JW Mariott Parq, Vancounver, Canada
                """
                , coordinate: .vancouver) {
                Image(systemName: "microphone.badge.ellipsis.fill")
                    .padding()
                    .frame(width: 30, height: 30)
                    .background {
                        Circle()
                            .foregroundStyle(.yellow)
                    }
            }
//            Marker("BEXCO exhibition, Busan, South Korea", coordinate: .busan)
            Annotation("""
                    Biosensors 2023
                    2023/06/05-06/08
                    Bexco, Busan, South Korea
                """
                , coordinate: .busan) {
                Image(systemName: "microphone.badge.ellipsis.fill")
                    .padding()
                    .frame(width: 30, height: 30)
                    .background {
                        Circle()
                            .foregroundStyle(.yellow)
                    }
            }
            
            Annotation("""
                    RSC-TIC 2019
                    2019/09/04-09/05
                    Makuhari Messe, Chiba, Japan
                """
                , coordinate: .chiba) {
                Image(systemName: "microphone.badge.ellipsis.fill")
                    .padding()
                    .frame(width: 30, height: 30)
                    .background {
                        Circle()
                            .foregroundStyle(.yellow)
                    }
            }
            Annotation("""
                    14th IEEE NEMS
                    2019/04/11-04/14
                    Marriott Marquis Queen’s Park, Bangkok, Thailand
                """
                , coordinate: .bangkok) {
                Image(systemName: "microphone.badge.ellipsis.fill")
                    .padding()
                    .frame(width: 30, height: 30)
                    .background {
                        Circle()
                            .foregroundStyle(.yellow)
                    }
            }
            
        }
        .frame(height: 320) // 關鍵：給定明確高度，避免在 ScrollView 中被壓成 0
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 6)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

#Preview {
    Travel()
}
