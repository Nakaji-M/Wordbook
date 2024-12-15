//
//  ShareExtensionView.swift
//  ShareToWordbook
//
//  Created by Masanori on 2024/08/30.
//

import SwiftUI

struct ShareExtensionView: View {
    @State private var url: String
    @State private var word: String
    @State private var meaning: String
    @State private var selectedTag: TagStoreItem? = nil
    @State private var showTagSelectionView = false
    @State var meaningId = false

    init(url: String, title: String, meaning: String, keywords: String, description: String) {
        self.url = url
        word = extractWord(url_string: url, title: title, keywords: keywords)
        if meaning.isEmpty{
            let settingsStore = SettingsStoreService()
            let replaceList = settingsStore.loadStringListSetting(settingKey: .webReplaceList)
            self.meaning = replaceList.reduce(description) { $0.replacingOccurrences(of: $1, with: "") }
        } else {
            self.meaning = meaning
        }
    }
    
    var body: some View {
        NavigationStack{
            ScrollView{
                VStack (alignment: .leading, spacing: 0){
                    NavigationLink(destination: TagSelectionView(selectedTag: $selectedTag)){
                        HStack(spacing: 8) {
                            Label("Tag", systemImage: "tag")
                            Spacer()
                            Text(selectedTag?.name ?? "未設定")
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .opacity(0.5)
                        }
                        .padding(.vertical)
                    }
                    
                    Text("URL")
                    TextField("URLを入力してください", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .padding(.bottom)
                    
                    Text("英単語")
                    TextField("単語を入力してください", text: $word)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .padding(.bottom)
                    
                    //意味の入力欄
                    HStack{
                        Text("意味")
                        //自動入力ボタン
                        Spacer()
                        Button(action:  {
                            if let meaning = DictionaryService().getItemFromWord_vague(word: word){
                                self.meaning = meaning.mean
                            } else {
                                    self.meaning = "意味が見つかりませんでした"
                            }
                            meaningId.toggle() //意味の入力欄を更新(再描画)
                        }) {
                            Text("自動入力")
                                .foregroundColor(.accentColor)
                        }
                    }

                    TextField("意味を入力してください", text: $meaning, axis: .vertical)
                        .id(meaningId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .padding(.bottom)
                    
                    Button {
                        let word_add = WordStoreItem(word: word, meaning: meaning, url: url)
                        word_add.tag = selectedTag?.id
                        WordStoreService().inserrtWords(words_add: [word_add])
                        close()
                    } label: {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("単語の追加")
                .toolbar {
                    Button("Cancel") {
                        close()
                        
                    }
                }
            }
        }
    }
    
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
    }
}
