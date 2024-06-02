//
//  DefaultEmojiProvider.swift
//  
//
//  Created by Kévin Sibué on 11/01/2023.
//

import Foundation
import EmojiKit

public final class DefaultEmojiProvider: EmojiProvider {

    public init() { }

    public func getAll() -> [Emoji] {
        EmojiManager.getAvailableEmojis().compactMap {
            if let value = $0.values.first {
                Emoji(value: value, name: $0.name.rawValue)
            } else {
                nil
            }
        }
    }

}
