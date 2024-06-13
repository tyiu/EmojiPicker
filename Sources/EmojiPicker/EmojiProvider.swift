//
//  EmojiProvider.swift
//  
//
//  Created by Kévin Sibué on 13/01/2023.
//

import Foundation
import EmojiKit

public protocol EmojiProvider {
    var emojiCategories: [AppleEmojiCategory] { get }
    func find(query: String) -> [Emoji]
}
