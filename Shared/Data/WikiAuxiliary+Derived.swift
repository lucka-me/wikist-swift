//
//  WikiAuxiliary+Derived.swift
//  Wikist
//
//  Created by Lucka on 2/1/2023.
//

import Foundation

extension WikiAuxiliary {
    var namespaces: [ Int32 : WikiNamespace ] {
        set {
            let encoder = JSONEncoder()
            namespacesData = try? encoder.encode(newValue)
        }
        get {
            guard let namespacesData else { return [ : ] }
            let decoder = JSONDecoder()
            let result = try? decoder.decode([ Int32 : WikiNamespace ].self, from: namespacesData)
            return result ?? [ : ]
        }
    }
}
