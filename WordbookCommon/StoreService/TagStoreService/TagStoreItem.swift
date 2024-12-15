//
//  TagStoreItem.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/12/15.
//

import Foundation

class TagStoreItem: Identifiable, Codable, Equatable{
    var name: String
    var id: UUID
    
    init(name: String) {
        self.name = name
        self.id = UUID()
    }
    static func == (lhs: TagStoreItem, rhs: TagStoreItem) -> Bool{
            return lhs.id == rhs.id
        }
}
