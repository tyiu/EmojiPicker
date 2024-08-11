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
    private var dismiss

    @Binding
    private var selectedEmoji: Emoji?

    @State
    private var skinTone1: SkinTone

    @State
    private var skinTone2: SkinTone

    @State
    private var search: String = ""

    @State
    private var isShowingSettings: Bool = false

    @State
    private var emojiProvider: EmojiProvider = DefaultEmojiProvider(showAllVariations: true)

    private let demoSkinToneEmojis: [String] = [
        "👍",
        "🧍",
        "🧑",
        "🤝",
        "🧑‍🤝‍🧑",
        "💏",
        "💑"
    ]

    public init(
            selectedEmoji: Binding<Emoji?>,
            emojiProvider: EmojiProvider = DefaultEmojiProvider(showAllVariations: true)
    ) {
        self._selectedEmoji = selectedEmoji
        self._emojiProvider = State(initialValue: emojiProvider) // Initialize emojiProvider first

        // Now you can safely set skinTone1 and skinTone2
        self._skinTone1 = State(initialValue: emojiProvider.skinTone1)
        self._skinTone2 = State(initialValue: emojiProvider.skinTone2)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 36))
    ]

    private var searchResults: [Emoji] {
        if search.isEmpty {
            return []
        } else {
            return emojiProvider.find(query: search)
        }
    }

    private func emojiVariation(_ emoji: Emoji) -> Emoji {
        let unqualifiedNeutralEmoji = EmojiManager.unqualifiedNeutralEmoji(for: emoji.value)
        if (skinTone1 == .neutral && skinTone2 == .neutral)
                   || emojiProvider.variations[unqualifiedNeutralEmoji] == nil {
            // Show neutral emoji if both skin tones are neutral.
            return emoji
        } else if let variation = emojiProvider.variation(
                for: emoji.value,
                skinTone1: skinTone1,
                skinTone2: skinTone2
        ) {
            // Show skin tone combination if the variation exists.
            return variation
        } else if skinTone2 == .neutral, let variation = emojiProvider.variation(
                for: emoji.value,
                skinTone1: skinTone1,
                skinTone2: skinTone1
        ) {
            // If only the second skin tone is neutral,
            // look up only variations where the second skin tone is the same as the first.
            return variation
        } else {
            // If none of the above are found, show the neutral emoji.
            return emoji
        }
    }

    private func emojiView(emoji: Emoji, category: AppleEmojiCategory?) -> some View {
        RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .frame(width: 36, height: 36)
                .overlay {
                    Text(emojiVariation(emoji).value)
                            .font(.largeTitle)
                }
    }

    private func emojiViewInteractive(emoji: Emoji, category: AppleEmojiCategory?) -> some View {
        emojiView(emoji: emoji, category: category)
                .onTapGesture {
                    emoji.incrementUsageCount()
                    selectedEmoji = emojiVariation(emoji)
                    dismiss()
                }
    }

    private func sectionHeaderView(_ categoryName: EmojiCategory.Name) -> some View {
        ZStack {
            #if os(iOS)
            Color(.systemBackground)
                    .frame(maxWidth: .infinity) // Ensure background spans full width
            #else
            Color(.windowBackgroundColor)
                    .frame(maxWidth: .infinity) // Ensure background spans full width
            #endif
            Text(categoryName.localizedName)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading) // Ensure text is aligned
        }
                .zIndex(1) // Ensure header is on top
    }

    public var body: some View {
        ScrollViewReader { proxy in
            VStack {

                #if os(macOS)
                EmojiSearchView(search: $search)
                Divider()
                #endif

                if isShowingSettings {
                    VStack {
                        settingsView
                    }
                            .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, alignment: .leading, pinnedViews: [.sectionHeaders]) {
                            if search.isEmpty {
                                Section {
                                    ForEach(emojiProvider.frequentlyUsedEmojis.map {
                                        $0.sectionedEmoji(EmojiCategory.Name.frequentlyUsed)
                                    }, id: \.self) { sectionedEmoji in
                                        emojiViewInteractive(emoji: sectionedEmoji.emoji, category: nil)
                                    }
                                } header: {
                                    sectionHeaderView(EmojiCategory.Name.frequentlyUsed)
                                }
                                        .id(EmojiCategory.Name.frequentlyUsed)
                                        .frame(alignment: .leading)

                                ForEach(emojiProvider.emojiCategories, id: \.self) { category in
                                    Section {
                                        ForEach(category.emojis.values, id: \.self) { emoji in
                                            emojiViewInteractive(emoji: emoji, category: category)
                                        }
                                    } header: {
                                        sectionHeaderView(category.name)
                                    }
                                            .id(category.name)
                                            .frame(alignment: .leading)
                                }
                            } else {
                                ForEach(searchResults, id: \.self) { emoji in
                                    emojiViewInteractive(emoji: emoji, category: nil)
                                }
                            }
                        }
                                .padding(.horizontal)
                    }
                            .frame(maxHeight: .infinity)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
                            .textInputAutocapitalization(.never)
                            #endif
                }

                VStack {
                    EmojiCategoryPicker(sections: EmojiCategory.Name.orderedCases, selectionHandler: { emojiCategoryName in
                        search = ""
                        isShowingSettings = false
                        proxy.scrollTo(emojiCategoryName, anchor: .top)
                    }).padding(8)
                }.overlay {
                            RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        }
            }
        }
    }

    private var settingsView: some View {
        Form {
            Section {
                HStack {
                    ForEach(demoSkinToneEmojis, id: \.self) {
                        emojiView(emoji: Emoji(value: $0, localizedKeywords: [:]), category: nil)
                                .frame(alignment: .center)
                    }
                }

                Picker(
                        NSLocalizedString("firstSkinTone",
                                tableName: "EmojiPickerLocalizable",
                                bundle: .module,
                                comment: ""),
                        selection: $skinTone1
                ) {
                    ForEach(SkinTone.allCases, id: \.self) { skinTone in
                        Text(skinTone.rawValue)
                    }
                }
                        .pickerStyle(.segmented)
                        .onChange(of: skinTone1) { newSkinTone in
                            emojiProvider.skinTone1 = newSkinTone
                        }

                Picker(
                        NSLocalizedString("secondSkinTone",
                                tableName: "EmojiPickerLocalizable",
                                bundle: .module,
                                comment: ""),
                        selection: $skinTone2
                ) {
                    ForEach(SkinTone.allCases, id: \.self) { skinTone in
                        Text(skinTone.rawValue)
                    }
                }
                        .pickerStyle(.segmented)
                        .onChange(of: skinTone2) { newSkinTone in
                            emojiProvider.skinTone2 = newSkinTone
                        }
            } header: {
                Text(NSLocalizedString("skinToneHeader",
                        tableName: "EmojiPickerLocalizable",
                        bundle: .module,
                        comment: ""))
            }

            Section {
                Button {
                    emojiProvider.removeFrequentlyUsedEmojis()
                } label: {
                    Text(NSLocalizedString("reset",
                            tableName: "EmojiPickerLocalizable",
                            bundle: .module,
                            comment: ""))
                }
            } header: {
                Text(EmojiCategory.Name.frequentlyUsed.localizedName)
            }
        }
    }

    private var settingsTab: some View {
        Image(systemName: "gear")
                .font(.system(size: 20))
                .frame(width: 24, height: 24)
                .foregroundColor(isShowingSettings
                        ? Color.accentColor : .secondary)
                .onTapGesture {
                    search = ""
                    isShowingSettings = true
                }
    }

}

extension AppleEmojiCategory.Name {
    var imageName: String {
        switch self {
        case .frequentlyUsed:
            return "clock"
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

extension Emoji {
    func sectionedEmoji(_ categoryName: EmojiCategory.Name) -> SectionedEmoji {
        SectionedEmoji(emoji: self, categoryName: categoryName)
    }
}

struct SectionedEmoji: Hashable {
    let emoji: Emoji
    let categoryName: EmojiCategory.Name
}

struct EmojiPickerView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiPickerView(selectedEmoji: .constant(Emoji(value: "", localizedKeywords: [:])), emojiProvider: DefaultEmojiProvider(showAllVariations: false))
    }
}
