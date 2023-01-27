//
//  AppIcon.swift
//  Wikist
//
//  Created by Lucka on 23/1/2023.
//

import Foundation
#if os(iOS)
import UIKit
#endif

enum AppIcon: String, CaseIterable, Identifiable {
    case primary = "AppIcon"
#if os(iOS)
    case primaryDark = "AppIcon-Dark"
    case classic = "AppIcon-Classic"
    case classicDark = "AppIcon-Classic-Dark"
#endif
    
    static var current: AppIcon {
#if os(iOS)
        guard
            let iconName = UIApplication.shared.alternateIconName,
            let icon = AppIcon(rawValue: iconName)
        else {
            return .primary
        }
        return icon
#else
        return .primary
#endif
    }
    
    var id: String { self.rawValue }
    var previewName: String { self.rawValue + "-Preview" }
}
