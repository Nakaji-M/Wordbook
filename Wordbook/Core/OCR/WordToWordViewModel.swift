//
//  WordToWordViewModel.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/11.
//

import Foundation

func WordToWordViewModel(word_list: [Word]) -> [WordStoreItem] {
    var wordViewModels: [WordStoreItem] = []
    
    for word in word_list {
        let wordViewModel = WordStoreItem(word: word.wordString, meaning: word.meaningString, example: word.exampleSentenceString, note: "", isMemorized: false, isFavorite: false)
        wordViewModels.append(wordViewModel)
    }
    return wordViewModels
}
