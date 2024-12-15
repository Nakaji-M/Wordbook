//
//  AddWordsFromTextView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/08.
//

import SwiftUI

struct AddWordsFromTextView: View {
    @Binding var path: [AddWordsPath]
    //入力された英単語
    @State var viewModel = WordStoreItem(word: "", meaning: "", example: "", note: "", isMemorized: false, isFavorite: false)
    //選択されたタグ
    @State private var selectedTag: TagStoreItem?

    var body: some View {
        ScrollView{
            HStack{
                //英単語、意味、例文、メモの入力欄を表示
                VStack (alignment: .leading, spacing: 0){
                    //Tagを設定するためのページ
                    Button(action: {
                        path.append(.tagSelection(selectedTag: $selectedTag))
                    }) {
                        HStack(spacing: 8) {
                            Label("Tag", systemImage: "tag")
                            Spacer()
                            Text(selectedTag?.name ?? "未設定")
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .opacity(0.5)
                        }
                        .padding()
                        .padding(.vertical)
                    }
                    CommonWordEditView(viewModel: $viewModel)
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.tag = selectedTag?.id
                    MainTab.JSON?.inserrtWords(words_add: [viewModel])
                    path = []
                }) {
                    Label("保存", systemImage: "square.and.arrow.down")
                        .labelStyle(TitleOnlyLabelStyle())
                }
            }
        }
        .navigationBarTitle("単語追加")
    }
}
