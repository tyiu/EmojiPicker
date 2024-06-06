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
        return EmojiManager.getAvailableEmojis().flatMap { $0.emojis.values }
    }

}
