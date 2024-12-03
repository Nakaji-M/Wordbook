//
//  AddWordFromListView.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/26.
//

import SwiftUI
import SwiftData

struct AddWordFromListView: View {
    //入力された英単語
    @State var word = Word(word: "", meaning: "", example: "", note: "", isMemorized: false, isFavorite: false)
    //選択されたタグ
    @State var selectedTag: Tag?
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    
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
                        CommonWordEditView(word: $word)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        word.tag = selectedTag?.id
                        context.insert(word)
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

