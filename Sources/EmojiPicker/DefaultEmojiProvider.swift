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
    private let showAllVariations: Bool

    private let emojiCategoriesCache: [EmojiCategory]
    private let trie: Trie<Emoji>

    private let allVariations: [String: [Emoji]]

    // Unicode ranges for skin tone modifiers
    private let skinToneRange: ClosedRange<UInt32> = 0x1F3FB...0x1F3FF

    public init(showAllVariations: Bool) {
        let trie = Trie<Emoji>()
        let emojiCategories = EmojiManager.getAvailableEmojis(showAllVariations: showAllVariations)
        var allVariations = [String: [Emoji]]()

        emojiCategories.forEach { category in
            category.emojis.forEach { emoji in
                let emojiValue = emoji.value.value

                // Insert the emoji itself as a searchable string in the trie.
                _ = trie.insert(key: emojiValue, value: emoji.value, options: [.includeNonPrefixedMatches])

                // Insert all the localized keywords for the emoji in the trie.
                emoji.value.localizedKeywords.forEach { locale in
                    locale.value.forEach { keyword in
                        _ = trie.insert(
                            key: keyword,
                            value: emoji.value,
                            options: [
                                .includeNonPrefixedMatches,
                                .includeCaseInsensitiveMatches,
                                .includeDiacriticsInsensitiveMatches
                            ]
                        )
                    }
                }
            }

            allVariations.merge(category.variations, uniquingKeysWith: { (current, _) in current })
        }

        self.showAllVariations = showAllVariations
        self.trie = trie
        self.emojiCategoriesCache = emojiCategories
        self.allVariations = allVariations
    }

    public var isShowingAllVariations: Bool {
        showAllVariations
    }

    // Function to check if a scalar is a skin tone modifier
    private func isSkinToneModifier(scalar: Unicode.Scalar) -> Bool {
        return skinToneRange.contains(scalar.value)
    }

    public var emojiCategories: [AppleEmojiCategory] {
        emojiCategoriesCache
    }

    public var variations: [String: [Emoji]] {
        allVariations
    }

    public func find(query: String) -> [Emoji] {
        let queryWithoutSkinTone = EmojiManager.neutralEmoji(for: query)
        return trie.find(key: queryWithoutSkinTone.localizedLowercase)
    }

    public func variation(for emojiValue: String, skinTone1: SkinTone, skinTone2: SkinTone) -> Emoji? {
        let unqualifiedNeutralEmoji = EmojiManager.unqualifiedNeutralEmoji(for: emojiValue)
        guard let variationsForEmoji = variations[unqualifiedNeutralEmoji] else {
            return nil
        }

        let skinTone1Scalar = skinTone1.unicodeScalarValue
        let skinTone2Scalar = skinTone2.unicodeScalarValue

        // Sort variations by number of skin tone modifiers so that we can find the variation
        // that matches closest to our skin tone search parameters.
        // Some emojis can have 0-2 skin tone modifier variations.
        // Some emojis can have 0-1 skin tone modifier variations.
        let sortedVariationsForEmoji = variationsForEmoji.sorted {
            let count1 = $0.value.unicodeScalars.filter { scalar in isSkinToneModifier(scalar: scalar) }.count
            let count2 = $1.value.unicodeScalars.filter { scalar in isSkinToneModifier(scalar: scalar) }.count

            return count1 > count2
        }

        for variation in sortedVariationsForEmoji {
            let skinToneScalars = variation.value.unicodeScalars
                .filter { isSkinToneModifier(scalar: $0) }.map { $0.value }

            switch skinToneScalars.count {
            case 0:
                continue
            case 1:
                if skinTone1Scalar == skinToneScalars[0] {
                    return variation
                }
            default:
                if skinTone1Scalar == skinToneScalars[0] && skinTone2Scalar == skinToneScalars[1] {
                    return variation
                }
            }
        }

        return nil
    }

    public var frequentlyUsedEmojis: [Emoji] {
        return Array(
            emojiCategoriesCache
                .flatMap { $0.emojis.values }
                .filter { $0.usageCount > 0 }
                .sorted(by: { lhs, rhs in
                    let (aUsage, bUsage) = (lhs.usage, rhs.usage)
                    guard aUsage.count != bUsage.count else {
                        // Break ties with most recent usage
                        return lhs.lastUsage > rhs.lastUsage
                    }
                    return aUsage.count > bUsage.count
                })
                .prefix(30)
        )
    }

    public func removeFrequentlyUsedEmojis() {
        emojiCategoriesCache
            .flatMap { $0.emojis.values }
            .filter { $0.usageCount > 0 }
            .forEach {
                UserDefaults.standard.removeObject(forKey: StorageKeys.usageTimestamps($0).key)
            }
    }

    public var skinTone1: SkinTone {
        get {
            guard let skinToneScalar = UserDefaults.standard.object(forKey: StorageKeys.skinTone1.key) as? UInt32 else {
                return .neutral
            }
            return SkinTone.allCases.first(where: {
                $0.unicodeScalarValue == skinToneScalar
            }) ?? .neutral
        }
        set {
            if newValue != .neutral, let unicodeScalarValue = newValue.unicodeScalarValue {
                UserDefaults.standard.set(unicodeScalarValue, forKey: StorageKeys.skinTone1.key)
            } else {
                UserDefaults.standard.removeObject(forKey: StorageKeys.skinTone1.key)
            }
        }
    }

    public var skinTone2: SkinTone {
        get {
            guard let skinToneScalar = UserDefaults.standard.object(forKey: StorageKeys.skinTone2.key) as? UInt32 else {
                return .neutral
            }
            return SkinTone.allCases.first(where: { $0.unicodeScalarValue == skinToneScalar }) ?? .neutral
        }
        set {
            if newValue != .neutral, let unicodeScalarValue = newValue.unicodeScalarValue {
                UserDefaults.standard.set(unicodeScalarValue, forKey: StorageKeys.skinTone2.key)
            } else {
                UserDefaults.standard.removeObject(forKey: StorageKeys.skinTone2.key)
            }
        }
    }
}

private enum StorageKeys {
    case skinTone1
    case skinTone2
    case usageTimestamps(_ emoji: Emoji)

    var key: String {
        switch self {
        case .skinTone1:
            return "emojipicker-skintone1"
        case .skinTone2:
            return "emojipicker-skintone2"
        case .usageTimestamps(let emoji):
            return "emojipicker-usage-timestamps-" + EmojiManager.unqualifiedNeutralEmoji(for: emoji.value)
        }
    }
}

extension Emoji {
    /// All times when the emoji has been selected.
    var usage: [TimeInterval] {
        (UserDefaults.standard.array(forKey: StorageKeys.usageTimestamps(self).key) as? [TimeInterval]) ?? []
    }
    /// The number of times this emoji has been selected.
    var usageCount: Int {
        usage.count
    }
    /// The last time when this emoji has been selected.
    var lastUsage: TimeInterval {
        usage.first ?? .zero
    }

    /// Increments the usage count for this emoji.
    func incrementUsageCount() {
        let nowTimestamp = Date().timeIntervalSince1970
        UserDefaults.standard.set([nowTimestamp] + usage, forKey: StorageKeys.usageTimestamps(self).key)
    }
}
