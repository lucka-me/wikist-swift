//
//  WikiNamespace.swift
//  Wikist
//
//  Created by Lucka on 2/1/2023.
//

import Foundation

struct WikiNamespace: Codable {
    var id: Int32
    var name: String
    var canonical: String?
}
