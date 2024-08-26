//
// Created by tddworks on 8/11/24.
//

import SwiftUI

struct EmojiSearchView: View {
    @Binding var search: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                    .padding(.leading, 8)
            TextField("Search emojis",
                    text: $search)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(Font.system(size: 12))

        }
                .frame(height: 32)
                .padding(.horizontal, 8)
    }
}
