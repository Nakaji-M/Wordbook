//
//  Tag.swift
//  ShareToWordbook
//
//  Created by Masanori on 2024/09/01.
//

import SwiftUI
import SwiftData

@Model
class Tag: Identifiable{
    var name: String
    var id: UUID
    
    init(name: String) {
        self.name = name
        self.id = UUID()
    }
}
