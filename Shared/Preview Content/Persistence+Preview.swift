//
//  Persistence+Preview.swift
//  Wikist
//
//  Created by Lucka on 7/1/2023.
//

import CoreData

#if DEBUG
extension Persistence {
    static func previewUser(with context: NSManagedObjectContext) -> User {
        let wiki = previewWiki(with: context)
        let user = User(name: "卢卡", wiki: wiki, context: context)
        let now = Date()
        for number in 0...5 {
            let day = Calendar.current.date(byAdding: .day, value: -number, to: now)!
            for _ in 0...number * 10 {
                let contribution = Contribution(context: context)
                contribution.userID = user.uuid
                contribution.pageID = Int64.random(in: 1...Int64.max)
                contribution.revisionID = Int64.random(in: 1...Int64.max)
                contribution.timestamp = day
                contribution.title = "Page \(Int.random(in: 1...Int.max))"
            }
        }
        return user
    }
    
    static func previewWiki(with context: NSManagedObjectContext) -> Wiki {
        let wiki = Wiki(api: URL(string: "https://wiki.52poke.com/api.php")!, context: context)
        wiki.title = "神奇宝贝百科"
        return wiki
    }
}
#endif
