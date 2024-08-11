//
// Created by tddworks on 2024/8/1.
//

import SwiftUI
import EmojiKit

public struct EmojiCategoryPicker: View {

    @State var currentCategory: EmojiCategory.Name = EmojiCategory.Name.flags

    private var sections: [EmojiCategory.Name]

    private var selectionHandler: (EmojiCategory.Name) -> Void

    public init(sections: [EmojiCategory.Name], selectionHandler: @escaping (EmojiCategory.Name) -> Void) {
        self.sections = sections
        self.selectionHandler = selectionHandler
    }

    public var body: some View {
        SegmentedControl(selection: $currentCategory, dataSource: sections, images: sections.map {
                    NSImage(systemSymbolName: $0.imageName, accessibilityDescription: nil)
                }
                .compactMap {
                    $0
                }, selectionHandler: selectionHandler)
    }
}


struct EmojiCategoryPicker_Previews: PreviewProvider {
    static var previews: some View {
        let sections = EmojiCategory.Name.orderedCases
        EmojiCategoryPicker(sections: sections, selectionHandler: { emojiCategoryName in })
    }
}

struct Blur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .withinWindow
        view.material = .hudWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.blendingMode = .withinWindow
        nsView.material = .hudWindow
    }
}

struct SegmentedControl<T: Hashable>: NSViewRepresentable {
    @Binding var selection: T

    private let images: [NSImage]
    private let dataSource: [T]
    private let selectionHandler: (T) -> Void

    init(selection: Binding<T>, dataSource: [T], images: [NSImage], selectionHandler: @escaping (T) -> Void) {
        self._selection = selection
        self.images = images
        self.dataSource = dataSource
        self.selectionHandler = selectionHandler
    }

    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl(images: images, trackingMode: .selectOne, target: context.coordinator, action: #selector(Coordinator.onChange(_:)))
        return control
    }

    func updateNSView(_ nsView: NSSegmentedControl, context: Context) {
        nsView.selectedSegment = dataSource.firstIndex(of: selection) ?? 0
    }

    func makeCoordinator() -> SegmentedControl.Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator {
        let parent: SegmentedControl

        init(parent: SegmentedControl) {
            self.parent = parent
        }

        @objc
        func onChange(_ control: NSSegmentedControl) {
            let selection = parent.dataSource[control.selectedSegment]
            parent.selection = selection
            parent.selectionHandler(selection)
        }
    }
}
