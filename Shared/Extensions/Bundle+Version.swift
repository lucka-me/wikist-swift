//
//  Bundle+Version.swift
//  Wikist
//
//  Created by Lucka on 14/12/2022.
//

import Foundation

extension Bundle {
    var shortVersionString: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    }
    
    var version: Int {
        guard let text = infoDictionary?["CFBundleVersion"] as? String else { return 0 }
        return .init(text) ?? 0
    }
}
