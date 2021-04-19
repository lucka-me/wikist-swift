//
//  PreferencesView.swift
//  Wikist
//
//  Created by Lucka on 14/4/2021.
//

import SwiftUI

struct PreferencesView: View {
    
    @ObservedObject private var support = Support.shared
    @State private var presentingIconSelector = false
    @State private var presentingTipAction = false
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        List {
            Section(header: Text("view.preferences.appearance")) {
                if UIApplication.shared.supportsAlternateIcons {
                    Button(action: changeIcon) {
                        Label("view.preferences.appearance.changeIcon", systemImage: "app")
                    }
                }
            }
            
            Section(header: Text("view.preferences.about")) {
                if Support.shared.canMakePayments {
                    Button {
                        presentingTipAction = true
                    } label: {
                        Label("view.tip", systemImage: "gift")
                    }
                }
                
                Link(destination: URL(string: "https://github.com/lucka-me/wikist-swift")!) {
                    Label("view.preferences.about.sourceCode", systemImage: "swift")
                }
                
                Label("view.preferences.about.version \(version)", systemImage: "info")
            }
        }
        .listStyle(InsetGroupedListStyle())
        .sheet(isPresented: $presentingIconSelector) {
            IconSelector()
        }
        .actionSheet(isPresented: $presentingTipAction) {
            .init(
                title: Text("view.tip.choose"),
                buttons: tipActionButtons
            )
        }
        .alert(isPresented: $support.purchased) {
            .init(title: Text("view.tip.thanks"))
        }
    }
    
    private var tipActionButtons: [ActionSheet.Button] {
        var list: [ActionSheet.Button] = support.products.map { product in
            .default(Text(product.localizedText)) {
                support.purchase(product)
            }
        }
        list.append(.cancel())
        return list
    }
    
    private var version: String {
        guard let infoDict = Bundle.main.infoDictionary else {
            return "Unknown"
        }
        let shortVersion = infoDict["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = infoDict["CFBundleVersion"] as? String ?? "Unknown"
        return "\(shortVersion) (\(build))"
    }
    
    private func changeIcon() {
        presentingIconSelector = true
    }
}

#if DEBUG
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
#endif

fileprivate struct IconSelector: View {
    
    static private let light = "AppIcon60x60"
    static private let dark = "AppIconDark"
    
    @Environment(\.presentationMode) private var presentationMode
    @State private var selected = UIApplication.shared.alternateIconName ?? Self.light
    
    var body: some View {
        NavigationView {
            List {
                row(Self.light, "Light")
                row(Self.dark, "Dark")
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("view.preferences.changeIcon")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("view.action.dismiss") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func row(_ icon: String, _ description: String) -> some View {
        Button {
            select(icon)
        } label: {
            HStack {
                Image(uiImage: UIImage(named: icon) ?? .init())
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .mask(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(width: 60, height: 60, alignment: .center)
                    .padding(6)
                Text(description)
                Spacer()
                if icon == selected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private func select(_ icon: String) {
        let name = Self.light == icon ? nil : icon
        UIApplication.shared.setAlternateIconName(name) { error in
            if error == nil {
                selected = icon
            }
        }
    }
}
