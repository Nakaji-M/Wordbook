//
//  WordEditView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/26.
//

import SwiftUI

struct CommonWordEditView: View {
    @Binding var viewModel: WordStoreItem
    @Binding var showLoadingAlert: Bool
    @Binding var alertMessage: String
    @State var meaningId = false
    @State var relatedWordsId = false

    //選択されたタグ
    @State private var selectedTag: Tag?

    var body: some View {
            //英単語、意味、例文、メモの入力欄を表示
            VStack (alignment: .leading, spacing: 0){
                //英単語の入力欄
                Text("英単語")
                TextField("単語を入力してください", text: $viewModel.word)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .padding(.bottom)
                
                //関連語の入力フォーム
                Text("関連語")
                VStack{
                    ForEach(viewModel.relatedWords.indices, id: \.self) { index in
                        HStack {
                            TextField("単語", text: $viewModel.relatedWords[index].word)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("意味", text: $viewModel.relatedWords[index].meaning)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(role: .destructive) {
                                viewModel.relatedWords.remove(at: index)
                                relatedWordsId.toggle()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 3)
                        .padding(.horizontal, 12)
                    }
                    Button(action: {
                        viewModel.relatedWords.append(RelatedWordItem(word: "", meaning: ""))
                        relatedWordsId.toggle()
                    }) {
                        Label("追加", systemImage: "plus")
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                }
                .overlay(content: {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(UIColor.secondarySystemGroupedBackground), lineWidth: 1)
                })
                .padding(.bottom)
                .id(relatedWordsId)

                //意味の入力欄
                HStack{
                    Text("意味")
                    //自動入力ボタン
                    Spacer()
                    Button(action:  {
                        alertMessage = "自動入力中..."
                        showLoadingAlert = true
                        if let meaning = DictionaryService().getItemFromWord_vague(word: viewModel.word){
                            self.viewModel.meaning = meaning.mean
                        } else {
                                self.viewModel.meaning = "意味が見つかりませんでした"
                        }
                        meaningId.toggle() //意味の入力欄を更新(再描画)
                        showLoadingAlert = false
                    }) {
                        Text("自動入力")
                            .foregroundColor(.accentColor)
                    }
                }
                TextField("意味を入力してください", text: $viewModel.meaning, axis: .vertical)
                    .id(meaningId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .padding(.bottom)
                
                //例文の入力欄
                Text("例文")
                TextField("例文を入力してください", text: $viewModel.example, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .padding(.bottom)
                
                //メモの入力欄
                Text("メモ")
                TextField("メモを入力してください", text: $viewModel.note, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .padding(.bottom)
                
                //URLの入力欄
                Text("URL")
                TextField("URLを入力してください", text: $viewModel.url, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .padding(.bottom)
                
                Toggle(isOn: $viewModel.isMemorized){
                    Text("覚えた")
                }
            }
    }
}

