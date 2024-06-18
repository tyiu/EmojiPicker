//
//  EmojiProvider.swift
//  
//
//  Created by Kévin Sibué on 13/01/2023.
//

import Foundation
import EmojiKit

public protocol EmojiProvider {
    var isShowingAllVariations: Bool { get }
    var emojiCategories: [AppleEmojiCategory] { get }
    var variations: [String: [Emoji]] { get }
    var skinTone1: SkinTone { get set }
    var skinTone2: SkinTone { get set }
    var frequentlyUsedEmojis: [Emoji] { get }
    func removeFrequentlyUsedEmojis()
    func find(query: String) -> [Emoji]
    func variation(for emojiValue: String, skinTone1: SkinTone, skinTone2: SkinTone) -> Emoji?
}
