//
//  NSManagedObjectWithFetchRequest.swift
//  Wikist
//
//  Created by Lucka on 19/4/2021.
//

import CoreData

protocol NSManagedObjectWithFetchRequest : NSManagedObject {
    static func fetchRequest() -> NSFetchRequest<Self>;
}
