//
//  RelatedWordsView.swift
//  Wordbook
//
//  Created by Masanori on 2024/09/11.
//

import SwiftUI
import SwiftData

struct RelatedWordsView: View {
    @Binding var path: [WordListPath]
    @Environment(\.modelContext) private var context
    @Query var words: [Word]
    @State var showAllMeaning: Bool = false
    @State var wordsShowOption: WordsShowOption = .all
    let originalWord: Word
    
    var relatedWords: [Word] {
        let filteredItems = words.compactMap { item in
            let wordContainsQuery = originalWord.relatedWords.contains{
                $0.word.lowercased() == item.word.lowercased()
            }
            return wordContainsQuery ? item : nil
        }
        return filteredItems
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(relatedWords) { wordViewModel in
                    WordListRowView(path: $path, word: Binding(get: { wordViewModel }, set: { _ in }), showAllMeaning: $showAllMeaning, wordsShowOption: $wordsShowOption)
                        .contentShape(Rectangle())
                        .onChange(of: wordViewModel.isFavorite) {
                            //お気に入りの変更があったらJSONに保存
                            try! context.save()
                        }
                }
            }
        }
        .navigationTitle("\(originalWord.word)の関連語")
    }
}
