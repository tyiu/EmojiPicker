//
//  EmojiPickerView.swift
//  
//
//  Created by Kévin Sibué on 11/01/2023.
//

import SwiftUI
import EmojiKit
import SwiftTrie

public struct EmojiPickerView: View {

    @Environment(\.dismiss)
    var dismiss

    @Binding
    public var selectedEmoji: Emoji?

    @State
    var selectedCategoryName: EmojiCategory.Name = .smileysAndPeople

    @State
    private var search: String = ""

    private var selectedColor: Color

    private let emojiCategories: [AppleEmojiCategory]
    private let emojiProvider: EmojiProvider

    public init(selectedEmoji: Binding<Emoji?>, selectedColor: Color = Color.accentColor, emojiProvider: EmojiProvider = DefaultEmojiProvider()) {
        self._selectedEmoji = selectedEmoji
        self.selectedColor = selectedColor
        self.emojiProvider = emojiProvider
        self.emojiCategories = emojiProvider.emojiCategories
    }

    let columns = [
        GridItem(.adaptive(minimum: 36))
    ]

    private var searchResults: [Emoji] {
        if search.isEmpty {
            return []
        } else {
            return emojiProvider.find(query: search)
        }
    }

    public var body: some View {
        ScrollViewReader { proxy in
            VStack {
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .leading) {
                        if search.isEmpty {
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
                                            .onAppear {
                                                self.selectedCategoryName = category.name
                                            }
                                    }
                                } header: {
                                    Text(category.name.localizedName)
                                        .foregroundStyle(.gray)
                                        .padding(.vertical, 8)
                                }
                                .frame(alignment: .leading)
                                .id(category.name)
                                .onAppear {
                                    self.selectedCategoryName = category.name
                                }
                            }
                        } else {
                            ForEach(searchResults, id: \.self) { emoji in
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
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: .infinity)
                .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                if search.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(EmojiCategory.Name.orderedCases, id: \.self) { emojiCategoryName in
                            Image(systemName: emojiCategoryName.imageName)
                                .font(.system(size: 18))
                                .frame(width: 24, height: 24)
                                .foregroundColor(selectedCategoryName == emojiCategoryName ? Color.accentColor : .secondary)
                                .onTapGesture {
                                    selectedCategoryName = emojiCategoryName
                                    proxy.scrollTo(emojiCategoryName, anchor: .top)
                                }
                        }
                    }
                }
            }
        }
    }

}

extension AppleEmojiCategory.Name {
    var imageName: String {
        switch self {
        case .smileysAndPeople:
            return "face.smiling"
        case .animalsAndNature:
            return "teddybear"
        case .foodAndDrink:
            return "fork.knife"
        case .activity:
            return "basketball"
        case .travelAndPlaces:
            return "car"
        case .objects:
            return "lightbulb"
        case .symbols:
            return "music.note"
        case .flags:
            return "flag"
        }
    }
}

struct EmojiPickerView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiPickerView(selectedEmoji: .constant(Emoji(value: "", localizedKeywords: [:])))
    }
}
