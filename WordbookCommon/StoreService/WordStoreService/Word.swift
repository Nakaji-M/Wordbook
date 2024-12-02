//
//  Word.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/12/02.
//

import SwiftUI
import SwiftData

@Model
class Word: Identifiable{
    var word: String
    var meaning: String
    var example: String
    var note: String
    var relatedWords: [RelatedWord]
    var url: String
    var order: Int
    var isMemorized: Bool
    var isFavorite: Bool
    var added: Date
    var lastModified: Date
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
        self.added = Date()
        self.lastModified = Date()
        self.order = 0
    }
}

struct RelatedWord: Identifiable, Codable{
    var word: String
    var meaning: String
    var id = UUID()
    
    init(word: String, meaning: String) {
        self.word = word
        self.meaning = meaning
    }
}
