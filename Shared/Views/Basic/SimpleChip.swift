//
//  SimpleChip.swift
//  Wikist
//
//  Created by Lucka on 26/11/2022.
//

import SwiftUI

struct SimpleChip<Content: View>: View {
    
    private let titleKey: LocalizedStringKey
    private let systemImage: String
    private let content: Content
    
    init(_ titleKey: LocalizedStringKey, systemImage: String, @ViewBuilder content: () -> Content) {
        self.titleKey = titleKey
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Label(titleKey, systemImage: systemImage)
                .labelStyle(.monospacedIconOnly)
                .foregroundStyle(.tint)
            content
                .lineLimit(1)
        }
        .font(.callout)
        .chip()
    }
}

extension SimpleChip where Content == Text {
    init(_ titleKey: LocalizedStringKey, systemImage: String, contentTextKey: LocalizedStringKey) {
        self.titleKey = titleKey
        self.systemImage = systemImage
        self.content = Text(contentTextKey)
    }
    
    init<S: StringProtocol>(_ titleKey: LocalizedStringKey, systemImage: String, contentText: S) {
        self.titleKey = titleKey
        self.systemImage = systemImage
        self.content = Text(contentText)
    }
}

#if DEBUG
struct SimpleChipPreviews: PreviewProvider {
    static var previews: some View {
        SimpleChip("Language", systemImage: "character.book.closed", contentTextKey: "Chinese")
    }
}
#endif
