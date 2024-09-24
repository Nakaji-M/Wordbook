//
//  AddWordsFromTextView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/08.
//

import SwiftUI

struct AddWordsFromTextView: View {
    @State private var showLoadingAlert = false
    @State var alertMessage: String = ""

    @Binding var path: [Path]
    //入力された英単語
    @State var viewModel = WordStoreItem(word: "", meaning: "", example: "", note: "", isMemorized: false, isFavorite: false)
    //選択されたタグ
    @State private var selectedTag: Tag?

    var body: some View {
        ScrollView{
            HStack{
                //英単語、意味、例文、メモの入力欄を表示
                VStack (alignment: .leading, spacing: 0){
                    //Tagを設定するためのページ
                    Button(action: {
                        path.append(.tagSelection($selectedTag))
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
                    CommonWordEditView(viewModel: $viewModel, showLoadingAlert: $showLoadingAlert, alertMessage: $alertMessage)
                }
            }
            .padding()
        }
        .overlay(
            ZStack {
                if showLoadingAlert {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    LoadingAlert(alertMessage: $alertMessage)
                }
            }
        )
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    alertMessage = "保存中..."
                    showLoadingAlert = true
                    viewModel.tag = selectedTag?.id
                    MainTab.JSON?.inserrtWords(words_add: [viewModel])
                    showLoadingAlert = false
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
