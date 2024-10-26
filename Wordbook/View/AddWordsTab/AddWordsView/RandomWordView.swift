//
//  RandomWordView.swift
//  Wordbook
//
//  Created by Masanori on 2024/09/04.
//

import SwiftUI

struct RandomWordView: View {
    let dictionaryService = DictionaryService()
    @State var dictionaryModel = DictionaryModel(item_id: 0, word: "", mean: "", level: 0)
    @Binding var path: [AddWordsPath]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack{
                Text("今日の英単語")
                Spacer()
                NavigationLink(destination: AddWordsFromTextView(path: $path, viewModel: WordStoreItem(word: dictionaryModel.word, meaning: dictionaryModel.mean, example: "", note: "", isMemorized: false, isFavorite: false))){
                    Label("追加", systemImage: "plus")
                }
            }
            
            Text(dictionaryModel.word)
                .font(.title)
                .lineLimit(1, reservesSpace: false)
            
            Text(dictionaryModel.mean)
                .font(.title3)
                .lineLimit(4, reservesSpace: false)
        }
        .padding(.horizontal, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            dictionaryModel = dictionaryService.getRandomWord()
        }
    }
}
