//
//  PersistenceControllerEnvironmentKey.swift
//  Wikist
//
//  Created by Lucka on 9/7/2022.
//

import SwiftUI

fileprivate struct PersistenceEnvironmentKey: EnvironmentKey {
    static let defaultValue: Persistence = .shared
}

extension EnvironmentValues {
    var persistence: Persistence {
        get { self[PersistenceEnvironmentKey.self] }
        set { self[PersistenceEnvironmentKey.self] = newValue }
    }
}
