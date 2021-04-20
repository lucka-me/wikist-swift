//
//  RemoteImage.swift
//  Wikist
//
//  Created by Lucka on 20/4/2021.
//

import SwiftUI

struct RemoteImage: View {
    
    @ObservedObject private var model: RemoteImageModel
    
    private let url: String
    
    init(_ url: String) {
        model = RemoteImageModel(url)
        self.url = url
    }
    
    var body: some View {
        if let image = Image(data: model.data) {
            image
                .resizable()
                .scaledToFit()
        } else {
            EmptyView()
        }
    }
}

#if DEBUG
struct RemoteImage_Previews: PreviewProvider {
    static var previews: some View {
        RemoteImage("https://s0.52poke.wiki/assets/wikilogo.png")
            .frame(width: 100, height: 100)
    }
}
#endif

fileprivate final class RemoteImageModel: ObservableObject {
    
    @Published var data: Data?
    
    init(_ url: String) {
        URLSession.shared.dataTask(with: url) { data in
            DispatchQueue.main.async {
                self.data = data
            }
        }
    }
}
