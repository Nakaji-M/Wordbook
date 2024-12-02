//
//  WordListPath.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/26.
//

import SwiftUI

enum WordListPath: Hashable, Equatable {
    case wordList(isAllWords: Bool, tag: Tag?)
    case relatedWord(originalWord: Word)
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
    
    static func == (lhs: WordListPath, rhs: WordListPath) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    private var rawValue: Int {
        switch self {
            case .relatedWord: return 0
            case .wordList: return 1
        }
    }
}
