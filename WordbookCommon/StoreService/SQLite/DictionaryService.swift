//
//  DictionaryService.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/26.
//

import Foundation
import GRDB

class DictionaryService {
    let appGroupId = "group.wordbook.common"

    func DictionaryRetriever() -> URL {
        guard let dirURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            fatalError("フォルダURL取得エラー")
        }
        let dbUrl = dirURL.appendingPathComponent("ejdict.sqlite3")
        if !FileManager.default.fileExists(atPath: dbUrl.path) {
            //move the file
            do {
                try FileManager.default.copyItem(at: Bundle.main.url(forResource: "ejdict", withExtension: "sqlite3")!, to: dbUrl)
            } catch {
                print(error)
                fatalError(error.localizedDescription)
            }
        }
        return dbUrl
    }
    
    func getItemFromWord(word: String) -> DictionaryModel? {
        var dictionaryModel: DictionaryModel? = nil
        let dbQueue = try! DatabaseQueue(path: DictionaryRetriever().path)
        try? dbQueue.read { db in
            dictionaryModel = try DictionaryModel.filter(Column("word") == word).fetchOne(db)
        }
        return dictionaryModel
    }
    
    func getItemFromWord_vague(word: String) -> DictionaryModel? {
        let word_search = word.trimmingCharacters(in: .whitespaces)
        var dictionaryModel: DictionaryModel? = nil
        let dbQueue = try! DatabaseQueue(path: DictionaryRetriever().path)
        try? dbQueue.read { db in
            dictionaryModel = try DictionaryModel.filter(Column("word") == word_search).fetchOne(db)
            if dictionaryModel == nil {
                dictionaryModel = try DictionaryModel.filter(Column("word") == word_search.lowercased()).fetchOne(db)
            }
        }
        return dictionaryModel
    }
    
    func getRandomWord() -> DictionaryModel {
        var dictionaryModel: DictionaryModel? = nil
        let dbQueue = try! DatabaseQueue(path: DictionaryRetriever().path)
        try? dbQueue.read { db in
            let dictionaryCount = try DictionaryModel.fetchCount(db)
            let randomIndex = Int.random(in: 1 ..< dictionaryCount + 1)
            dictionaryModel = try DictionaryModel.filter(Column("item_id") == randomIndex).fetchOne(db)
        }
        return dictionaryModel!
    }
}
