//
//  BriefCard.swift
//  Wikist
//
//  Created by Lucka on 10/7/2022.
//

import SwiftUI

struct BriefCard<Title: View, Content: View>: View {
    
    private let title: Title
    private let content: Content
    
    init(_ title: Title, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            title
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 4)
            content
                .font(.title)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .card()
        .labelStyle(.monospacedIconAndTitle)
    }
}

extension BriefCard where Title == Text {
    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = Text(title)
        self.content = content()
    }
    
    init(_ title: LocalizedStringKey, contentTextKey: LocalizedStringKey) where Content == Text {
        self.title = Text(title)
        self.content = Text(contentTextKey)
    }
    
    init<S: StringProtocol>(_ title: LocalizedStringKey, contentText: S) where Content == Text {
        self.title = Text(title)
        self.content = Text(contentText)
    }
}

extension BriefCard where Title == Label<Text, Image> {
    init(_ title: LocalizedStringKey, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = Label(title, systemImage: systemImage)
        self.content = content()
    }
    
    init(_ title: LocalizedStringKey, systemImage: String, contentTextKey: LocalizedStringKey) where Content == Text {
        self.title = Label(title, systemImage: systemImage)
        self.content = Text(contentTextKey)
    }
    
    init<S: StringProtocol>(_ title: LocalizedStringKey, systemImage: String, contentText: S) where Content == Text {
        self.title = Label(title, systemImage: systemImage)
        self.content = Text(contentText)
    }
}

#if DEBUG
struct BriefCardPreviews: PreviewProvider {
    static var previews: some View {
        BriefCard(Text("title")) {
            Text("Content")
        }
    }
}
#endif
