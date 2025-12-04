//
//  Colors.swift
//  stroymir
//
//  Created by Корнеев Александр on 08.04.2024.
//

import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct Colors {
    static let orange = Color(hex: "F0904F")
    static let textFieldOverlayGray = Color(hex: "B9B9B9")
    static let boldGray = Color(hex: "91919F")
    static let confrimCodeBackground = Color(hex: "F6F6F6")
    static let confrimCodeOverlay = Color(hex: "F1F1FA")
    static let lightGray2 = Color(hex: "EFEFEF")
    static let lightGrayOverlay = Color(hex: "E9E9E9")
    static let Red = Color(hex: "#D42B2B")
    static let Yellow = Color(hex: "#FDCD4A")
    static let Blue = Color(hex: "#288FEF")
    static let Green = Color(hex: "#1CBB49")
}

//288FEF
