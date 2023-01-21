//
//  AppIconSelector.swift
//  Wikist
//
//  Created by Lucka on 14/1/2023.
//

import SwiftUI

struct AppIconSelector: View {
    
    private enum AppIcon: String, CaseIterable, Identifiable {
        case primary = "AppIcon"
        case primaryDark = "AppIcon-Dark"
        case classic = "AppIcon-Classic"
        case classicDark = "AppIcon-Classic-Dark"
        
        var id: String { self.rawValue }
    }
    
    @State private var selection = AppIcon.primary
    
    var body: some View {
        List(AppIcon.allCases) { icon in
            Button {
                set(icon)
            } label: {
                HStack {
                    Image(icon.rawValue + "-Preview")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .mask {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(.secondary.opacity(0.5), lineWidth: 1)
                        }
                        .frame(width: 48, height: 48, alignment: .center)
                        .padding(.horizontal)
                    Spacer()
                    if selection == icon {
                        Label("AppIconSelector.Selection", systemImage: "checkmark.circle.fill")
                            .labelStyle(.iconOnly)
                    }
                }
            }
        }
        .onAppear {
            if
                let iconName = UIApplication.shared.alternateIconName,
                let icon = AppIcon(rawValue: iconName)
            {
                selection = icon
            } else {
                selection = .primary
            }
        }
        .navigationTitle("AppIconSelector.Title")
    }
    
    private func set(_ icon: AppIcon) {
        let iconName = icon == .primary ? nil : icon.rawValue
        guard UIApplication.shared.alternateIconName != iconName else { return }
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error {
                // TODO: Log error
                print(error)
            }
        }
        selection = icon
    }
}

struct AppIconSelector_Previews: PreviewProvider {
    static var previews: some View {
        AppIconSelector()
    }
}
