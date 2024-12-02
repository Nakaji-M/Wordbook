//
//  WordEditView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/26.
//

import SwiftUI

struct CommonWordEditView: View {
    @Binding var word: Word
    @State var meaningId = false
    @State var relatedWordsId = false
    @Environment(\.modelContext) private var context

    //選択されたタグ
    @State private var selectedTag: Tag?

    var body: some View {
            //英単語、意味、例文、メモの入力欄を表示
            VStack (alignment: .leading, spacing: 0){
                //英単語の入力欄
                Text("英単語")
                TextField("単語を入力してください", text: $word.word)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .padding(.bottom)
                
                //意味の入力欄
                HStack{
                    Text("意味")
                    //自動入力ボタン
                    Spacer()
                    Button(action:  {
                        if let meaning = DictionaryService().getItemFromWord_vague(word: word.word){
                            self.word.meaning = meaning.mean
                        } else {
                                self.word.meaning = "意味が見つかりませんでした"
                        }
                        meaningId.toggle() //意味の入力欄を更新(再描画)
                    }) {
                        Text("自動入力")
                            .foregroundColor(.accentColor)
                    }
                }
                TextField("意味を入力してください", text: $word.meaning, axis: .vertical)
                    .id(meaningId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .padding(.bottom)
                
                //関連語の入力フォーム
                Text("関連語")
                VStack{
                    ForEach(word.relatedWords.indices, id: \.self) { index in
                        HStack {
                            TextField("単語", text: $word.relatedWords[index].word)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("意味", text: $word.relatedWords[index].meaning)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(role: .destructive) {
                                word.relatedWords.remove(at: index)
                                try! context.save()
//                                relatedWordsId.toggle()
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 3)
                        .padding(.horizontal, 12)
                    }
                    Button(action: {
                        word.relatedWords.append(RelatedWord(word: "", meaning: ""))
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

                //例文の入力欄
                Text("例文")
                TextField("例文を入力してください", text: $word.example, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .padding(.bottom)
                
                //メモの入力欄
                Text("メモ")
                TextField("メモを入力してください", text: $word.note, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .padding(.bottom)
                
                //URLの入力欄
                Text("URL")
                TextField("URLを入力してください", text: $word.url, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .padding(.bottom)
                
                Toggle(isOn: $word.isMemorized){
                    Text("覚えた")
                }
            }
    }
}

