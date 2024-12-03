//
//  WordsListView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/07.
//

import SwiftUI
import SwiftData

struct WordbookListView: View {
    @State private var path = [WordListPath]()
    @Query(sort: \Tag.name) var tags: [Tag] = []
    @State var tag_delete: Tag?
    @State var isAllWords_delete = false
    @State private var showLoadingAlert = false
    @State var alertMessage: String = ""
    @State private var showDeleteAlert = false
    @State private var showAddWordSheet: Bool = false
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing){
                List {
                    Button(action: {
                        path.append(.wordList(isAllWords: true, tag: nil))
                    }){
                        HStack {
                            VStack(alignment: .leading, spacing: 8){
                                Text("全ての単語")
                                    .contentShape(Rectangle())
                            }
                        }.padding(.all)
                    }
                    .foregroundStyle(.primary)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(action: {
                            //確認のダイアログを表示
                            tag_delete = nil
                            isAllWords_delete = true
                            showDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    Button(action: {
                        path.append(.wordList(isAllWords: false, tag: nil))
                    }){
                        HStack {
                            VStack(alignment: .leading, spacing: 8){
                                Text("タグ未設定")
                                    .contentShape(Rectangle())
                            }
                        }.padding(.all)
                    }
                    .foregroundStyle(.primary)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(action: {
                            //確認のダイアログを表示
                            tag_delete = nil
                            isAllWords_delete = false
                            showDeleteAlert = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    
                    ForEach(tags) { tag in
                        Button(action: {
                            path.append(.wordList(isAllWords: false, tag: tag))
                        }){
                            HStack {
                                VStack(alignment: .leading, spacing: 8){
                                    Text(tag.name)
                                        .contentShape(Rectangle())
                                }
                            }.padding(.all)
                        }
                        .foregroundStyle(.primary)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(action: {
                                //確認のダイアログを表示
                                tag_delete = tag
                                isAllWords_delete = false
                                showDeleteAlert = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
                .overlay(
                    ZStack {
                        if showLoadingAlert {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            CommonLoadingAlertView(alertMessage: $alertMessage)
                        }
                    }
                )
                .alert(isPresented: $showDeleteAlert) {
                    Alert( title: Text("削除"), message: Text("本当に削除しますか？"), primaryButton: .destructive(Text("削除")) {
                        alertMessage = "削除中..."
                        showLoadingAlert = true
                        if isAllWords_delete{
                            //全ての単語を削除
                            let words = try! context.fetch(FetchDescriptor<Word>())
                            for word in words{
                                context.delete(word)
                            }
                                
                        }
                        else{
                            if tag_delete != nil{
                                //削除処理
                                context.delete(tag_delete!)
                            }
                            let words = try! context.fetch(FetchDescriptor<Word>(predicate: #Predicate { word in
                                word.tag == tag_delete
                            })
                            )
                            for word in words{
                                context.delete(word)
                            }
                        }
                        showLoadingAlert = false
                    }, secondaryButton: .cancel()
                    )
                }
                Button(action: {
                    self.showAddWordSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                .padding()
            }
            .sheet(isPresented: $showAddWordSheet)
            {
                AddWordFromListView(selectedTag: nil)
            }
            .navigationBarTitle("単語リスト")
            .navigationDestination(for: WordListPath.self) {
                switch $0 {
                case .wordList(isAllWords: let isAllWords_, tag: let tag_):
                    // 遷移先にpath配列の参照や必要な情報を渡す
                    WordListView(isAllWords: isAllWords_, tag: tag_, path: $path)
                case .relatedWord(originalWord: let originalWord_):
                    RelatedWordsView(path: $path, originalWord: originalWord_)
                }
            }
        }
    }
}
