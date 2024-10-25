//
//  RelatedWordsView.swift
//  Wordbook
//
//  Created by Masanori on 2024/09/11.
//

import SwiftUI

struct RelatedWordsView: View {
    @State var relatedWords: [WordStoreItem] = []
    @State var showAllMeaning: Bool = false
    @State var wordsShowOption: WordsShowOption = .all
    let originalWord: WordStoreItem
    
    var body: some View {
        VStack {
            List {
                ForEach($relatedWords) { $wordViewModel in
                    WordsListRow(viewModel: $wordViewModel, showAllMeaning: $showAllMeaning, wordsShowOption: $wordsShowOption)
                        .contentShape(Rectangle())
                        .onChange(of: wordViewModel.isFavorite) {
                            //お気に入りの変更があったらJSONに保存
                            MainTab.JSON?.updateWord(word_update: wordViewModel)
                        }
                }
            }
        }
        .onAppear {
            relatedWords = MainTab.JSON!.searchWords(words: originalWord.relatedWords.map { $0.word })
        }
        .navigationTitle("\(originalWord.word)の関連語")
    }
}
