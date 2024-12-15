//
//  WordViewModel.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/11.
//

import Foundation

class WordStoreItem: Identifiable, Codable{
    var word: String
    var meaning: String
    var example: String
    var note: String
    var relatedWords: [RelatedWordItem]
    var url: String
    var isMemorized: Bool
    var isFavorite: Bool
    var lastLearned: Date?
    var id = UUID() //上書きしないように注意
    var tag: UUID?
    
    init(word: String = "", meaning: String = "", example: String = "", note: String = "", url: String = "", isMemorized: Bool = false, isFavorite: Bool = false) {
        self.word = word
        self.meaning = meaning
        self.example = example
        self.note = note
        self.url = url
        self.isMemorized = isMemorized
        self.isFavorite = isFavorite
        self.relatedWords = []
    }
}

class RelatedWordItem: Identifiable, Codable{
    var word: String
    var meaning: String
    
    init(word: String, meaning: String) {
        self.word = word
        self.meaning = meaning
    }
}
