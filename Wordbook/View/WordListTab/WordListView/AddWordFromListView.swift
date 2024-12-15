//
//  AddWordFromListView.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/26.
//

import SwiftUI

struct AddWordFromListView: View {
    let onAdd: (WordStoreItem) -> Void
    //入力された英単語
    @State var viewModel = WordStoreItem(word: "", meaning: "", example: "", note: "", isMemorized: false, isFavorite: false)
    //選択されたタグ
    @State var selectedTag: TagStoreItem?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack{
            ScrollView{
                HStack{
                    //英単語、意味、例文、メモの入力欄を表示
                    VStack (alignment: .leading, spacing: 0){
                        //Tagを設定するためのページ
                        NavigationLink(destination: CommonTagSelectionView(selectedTag: $selectedTag)){
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
                        onAdd(viewModel)
                        dismiss()
                    }) {
                        Label("保存", systemImage: "square.and.arrow.down")
                            .labelStyle(TitleOnlyLabelStyle())
                    }
                }
            }
            .navigationBarTitle("単語追加")
        }
    }
}

