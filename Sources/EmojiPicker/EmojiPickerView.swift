//
//  EmojiPickerView.swift
//  
//
//  Created by Kévin Sibué on 11/01/2023.
//

import SwiftUI
import EmojiKit

public struct EmojiPickerView: View {

    @Environment(\.dismiss)
    var dismiss

    @Binding
    public var selectedEmoji: Emoji?

    @State
    private var search: String = ""

    private var selectedColor: Color
    private var searchEnabled: Bool

    private let emojiCategories: [AppleEmojiCategory]

    public init(selectedEmoji: Binding<Emoji?>, searchEnabled: Bool = false, selectedColor: Color = .blue, emojiProvider: EmojiProvider = DefaultEmojiProvider(), emojiCategories: [AppleEmojiCategory] = EmojiManager.getAvailableEmojis()) {
        self._selectedEmoji = selectedEmoji
        self.selectedColor = selectedColor
        self.searchEnabled = searchEnabled
        self.emojiCategories = emojiProvider.getAppleEmojiCategories()
    }

    let columns = [
        GridItem(.adaptive(minimum: 36))
    ]

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading) {
                ForEach(emojiCategories, id: \.self) { category in
                    Section {
                        ForEach(category.emojis.values, id: \.self) { emoji in
                            RoundedRectangle(cornerRadius: 16)
                                .fill((selectedEmoji == emoji ? selectedColor : Color.clear).opacity(0.4))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Text(emoji.value)
                                        .font(.largeTitle)
                                }
                                .onTapGesture {
                                    selectedEmoji = emoji
                                    dismiss()
                                }
                        }
                    } header: {
                        Text(category.name.localizedName)
                            .foregroundStyle(.gray)
                            .padding(.vertical, 8)
                    }
                    .frame(alignment: .leading)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }

}

struct EmojiPickerView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiPickerView(selectedEmoji: .constant(Emoji(value: "", keywords: [])))
    }
}
