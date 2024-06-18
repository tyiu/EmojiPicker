//
//  SkinTone.swift
//  
//
//  Created by Terry Yiu on 6/15/24.
//

import Foundation

public enum SkinTone: String, CaseIterable {
    case neutral = "🟨"
    case light = "🏻"
    case mediumLight = "🏼"
    case medium = "🏽"
    case mediumDark = "🏾"
    case dark = "🏿"

    static public var allCases: [SkinTone] = [
        .neutral,
        .light,
        .mediumLight,
        .medium,
        .mediumDark,
        .dark
    ]

    public var unicodeScalarValue: UInt32? {
        switch self {
        case .neutral:
            nil
        case .light:
            0x1F3FB
        case .mediumLight:
            0x1F3FC
        case .medium:
            0x1F3FD
        case .mediumDark:
            0x1F3FE
        case .dark:
            0x1F3FF
        }
    }
}
