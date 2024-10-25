//
//  WordListRow2WordStoreItemConverter.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/25.
//

import Foundation

class WordListRow2WordStoreItemConverter{
    let wordListRows: [WordListRow]
    
    init(wordListRows: [WordListRow]) {
        self.wordListRows = wordListRows
    }
    
    func GenerateWordStoreItem() -> [WordStoreItem] {
        func intersectY(rect1: CGRect, rect2: CGRect) -> Bool {
            let bool1 = rect1.minY < midPoint(bounds: rect2).y && midPoint(bounds: rect2).y < rect1.maxY
            let bool2 = rect2.minY < midPoint(bounds: rect1).y && midPoint(bounds: rect1).y < rect2.maxY
            return bool1 && bool2
        }
        
        var wordStoreItems: [WordStoreItem] = []
        for word in wordListRows {
            var word = word
            var meaningString = ""
            for i in 0..<word.meanings.count {
                if i != word.meanings.count - 1 {
                    if intersectY(rect1: word.meanings[i].box, rect2: word.meanings[i+1].box) && word.meanings[i+1].box.minY < word.meanings[i].box.minY {
                        (word.meanings[i], word.meanings[i+1]) = (word.meanings[i+1], word.meanings[i])
                    }
                }
                meaningString = meaningString + "\n" + word.meanings[i].text
            }
            let wordStoreItem = WordStoreItem(word: word.word.text, meaning: meaningString, example: "", note: "", isMemorized: false, isFavorite: false)
            wordStoreItems.append(wordStoreItem)
        }
        return wordStoreItems
    }
}

