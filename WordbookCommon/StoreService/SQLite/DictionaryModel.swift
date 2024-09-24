//
//  DictionaryModel.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/26.
//

import Foundation
import GRDB

struct DictionaryModel: Codable, FetchableRecord, PersistableRecord{
    // テーブル名
    static var databaseTableName: String {
        return "items"
    }
    
    // カラム名
    let item_id: Int
    let word: String
    let mean: String
    let level: Int
}
