//
//  TagStoreService.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/12/15.
//

import Foundation

class TagStoreService{
    private var tags: [TagStoreItem]
    let appGroupId = "group.wordbook.common"
    
    init() {
        self.tags = []
        loadJSON()
    }
    
    func storeJSON(tags: [TagStoreItem]){
        guard let dirURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            fatalError("フォルダURL取得エラー")
        }
        
        let fileURL = dirURL.appendingPathComponent("tags.json")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted //JSONデータを整形する
        guard let jsonValue = try? encoder.encode(tags) else {
            fatalError("JSONエンコードエラー")
        }
        
        do {
            try jsonValue.write(to: fileURL)
        } catch {
            fatalError("JSON書き込みエラー")
        }
    }
    
    func loadJSON(){
        guard let dirURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            fatalError("フォルダURL取得エラー")
        }

        let fileURL = dirURL.appendingPathComponent("tags.json")
        
        guard let jsonData = try? Data(contentsOf: fileURL) else {
            //初めての利用
            self.tags = []
            return
        }
        
        let decoder = JSONDecoder()
        do{
            self.tags = try decoder.decode([TagStoreItem].self, from: jsonData)
        }
        catch{
            fatalError("JSONデコードエラー")
        }
    }
    func getAllTags() -> [TagStoreItem]{
        return self.tags
    }
    func updateTag(word_update: TagStoreItem){
        self.tags = self.tags.map({$0.id == word_update.id ? word_update : $0})
        storeJSON(tags: tags)
    }
    func inserrtTags(tags_add: [TagStoreItem]){
        self.tags = self.tags + tags_add
        storeJSON(tags: tags)
    }
    func deleteTag(word_delete: TagStoreItem){
        self.tags = self.tags.filter({$0.id != word_delete.id})
        storeJSON(tags: tags)
    }
    func deleteAllTags(){
        self.tags = []
        storeJSON(tags: tags)
    }
}
