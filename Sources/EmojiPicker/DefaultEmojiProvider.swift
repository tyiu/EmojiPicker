//
//  DefaultEmojiProvider.swift
//  
//
//  Created by Kévin Sibué on 11/01/2023.
//

import Foundation
import EmojiKit
import SwiftTrie

public final class DefaultEmojiProvider: EmojiProvider {

    private let emojiCategoriesCache = EmojiManager.getAvailableEmojis()
    private let trie = Trie<Emoji>()

    // Unicode ranges for skin tone modifiers
    private let skinToneRanges: [ClosedRange<UInt32>] = [
        0x1F3FB...0x1F3FF // Skin tone modifiers
    ]

    public init() {
        emojiCategories.forEach { category in
            category.emojis.forEach { emoji in
                let emojiValue = emoji.value.value

                // Insert the emoji itself as a searchable string in the trie.
                let _ = trie.insert(key: emojiValue, value: emoji.value, options: [.includeNonPrefixedMatches])

                let emojiWithoutSkinTone = removeSkinTone(emojiValue)
                if emojiWithoutSkinTone != emojiValue {
                    let _ = trie.insert(key: emojiWithoutSkinTone, value: emoji.value, options: [.includeNonPrefixedMatches])
                }

                // Insert all the localized keywords for the emoji in the trie.
                emoji.value.localizedKeywords.forEach { locale in
                    locale.value.forEach { keyword in
                        let _ = trie.insert(key: keyword, value: emoji.value, options: [.includeNonPrefixedMatches, .includeCaseInsensitiveMatches, .includeDiacriticsInsensitiveMatches])
                    }
                }
            }
        }
    }

    // Function to check if a scalar is a skin tone modifier
    private func isSkinToneModifier(scalar: Unicode.Scalar) -> Bool {
        return skinToneRanges.contains { $0.contains(scalar.value) }
    }

    private func removeSkinTone(_ string: String) -> String {
        let filteredScalars = string.unicodeScalars.filter { !isSkinToneModifier(scalar: $0) }
        return String(String.UnicodeScalarView(filteredScalars))
    }

    public var emojiCategories: [AppleEmojiCategory] {
        emojiCategoriesCache
    }

    public func find(query: String) -> [Emoji] {
        let queryWithoutSkinTone = removeSkinTone(query)
        return trie.find(key: queryWithoutSkinTone.localizedLowercase)
    }

}
