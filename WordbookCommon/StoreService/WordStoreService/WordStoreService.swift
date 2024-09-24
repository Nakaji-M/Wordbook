//
//  StoreJSON.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/22.
//

import Foundation

class WordStoreService{
    private var words: [WordStoreItem]
    let appGroupId = "group.wordbook.common"
    
    init() {
        self.words = []
        loadJSON()
    }
    
    func storeJSON( words: [WordStoreItem]){
        guard let dirURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            fatalError("フォルダURL取得エラー")
        }
        
        let fileURL = dirURL.appendingPathComponent("words.json")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted //JSONデータを整形する
        guard let jsonValue = try? encoder.encode(words) else {
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

        let fileURL = dirURL.appendingPathComponent("words.json")
        
        guard let jsonData = try? Data(contentsOf: fileURL) else {
            //初めての利用
            self.words = []
            return
        }
        
        let decoder = JSONDecoder()
        do{
            self.words = try decoder.decode([WordStoreItem].self, from: jsonData)
        }
        catch{
            fatalError("JSONデコードエラー")
        }
    }
    
    func getWordsFromTag(tag: Tag?) -> [WordStoreItem]{
        return self.words.filter({$0.tag == tag?.id ?? nil})
    }
    
    func getAllWords() -> [WordStoreItem]{
        return self.words
    }
    
    func updateWord(word_update: WordStoreItem){
        self.words = self.words.map({$0.id == word_update.id ? word_update : $0})
        storeJSON(words: words)
    }
    
    func inserrtWords(words_add: [WordStoreItem]){
        self.words = self.words + words_add
        storeJSON(words: words)
    }
    
    func deleteWord(word_delete: WordStoreItem){
        self.words = self.words.filter({$0.id != word_delete.id})
        storeJSON(words: words)
    }
    func deleteWordsFromTag(tag_delete: Tag?){
        self.words = self.words.filter({$0.tag != tag_delete?.id ?? nil})
        storeJSON(words: words)
    }
    func deleteAllWords(){
        self.words = []
        storeJSON(words: words)
    }
    func searchWords(words: [String]) -> [WordStoreItem]{
        return self.words.filter({
            words.map({$0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()}).contains($0.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        })
    }
}
