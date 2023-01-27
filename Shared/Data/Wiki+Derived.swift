//
//  Wiki+Derived.swift
//  Wikist
//
//  Created by Lucka on 26/11/2022.
//

import Foundation

extension Wiki {
    var generatorVersion: String? {
        guard
            let generator,
            let match = generator.firstMatch(of: /\d+[\d\.]*/)
        else {
            return nil
        }
        return .init(match.output)
    }
    
    var mainPageURL: URL? {
        guard let mainPage else { return nil }
        return url(of: mainPage)
    }
    
    var auxiliary: WikiAuxiliary? {
        let values = value(forKey: "auxiliary") as? [ WikiAuxiliary ]
        return values?.first
    }
    
    func namespace(of id: Int32) -> WikiNamespace? {
        guard let auxiliary else { return nil }
        return auxiliary.namespaces[id]
    }
}
