//
//  WordsListView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/22.
//

import SwiftUI
import Translation
import SwiftData

struct WordListView: View {
    var isAllWords: Bool
    var tag: Tag?
    @Binding var path: [WordListPath]
    @State private var showLoadingAlert = false
    @State var alertMessage: String = ""
    @State private var showDeleteAlert = false
    @State var wordViewModel_delete: Word?
    @State private var showTagSheet = false
    @State var wordViewModel_edit: Word = Word()
    @State var showAllMeaning: Bool = false
    @State var wordsShowOption: WordsShowOption = .all
    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .latest
    @State private var showAddWordSheet: Bool = false
    @Query var words: [Word]
    @Environment(\.modelContext) private var context
    
    var filteredWords: [Word] {
        let filteredItems = words.compactMap { item in
            let wordContainsQuery = item.word.range(of: searchText,
                                                       options: .caseInsensitive) != nil
            let meaningContainsQuery = item.meaning.range(of: searchText,
                                                                        options: .caseInsensitive) != nil
            return (searchText.isEmpty || (wordContainsQuery || meaningContainsQuery)) && (wordsShowOption == .all || (wordsShowOption == .favorite && item.isFavorite) || (wordsShowOption == .memorized && !item.isMemorized)) ? item : nil
        }.sorted(by: { word1, word2 in
            switch sortOption {
            case .latest:
                return word1.added > word2.added
            case .oldest:
                return word1.added < word2.added
            case .alphabet:
                return word1.word < word2.word
            }
        })
        return filteredItems
    }

    
    init(isAllWords: Bool, tag: Tag?, path: Binding<[WordListPath]>) {
        self.isAllWords = isAllWords
        self.tag = tag
        self._path = path
        let tagId = self.tag?.id
        var predicate = #Predicate<Word> { _ in true }
        if !isAllWords {
          predicate = #Predicate<Word> { word in
              word.tag == tagId
          }
        }
        _words = Query<Word, [Word]>(filter: predicate, sort: \.word, order: .forward)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing){
            List {
                Section(header:
                            VStack{
                    //全ての意味を表示するかどうかを選択
                    Toggle(isOn: $showAllMeaning) {
                        Text("全単語の意味を表示")
                    }
                    //全ての項目を表示するか、お気に入りのみか、暗記していない単語のみかをPickerで選択
                    HStack{
                        Text("表示項目")
                            .font(.body)
                        Picker("", selection: $wordsShowOption) {
                            Text("全て").tag(WordsShowOption.all)
                            Text("お気に入り").tag(WordsShowOption.favorite)
                            Text("暗記未完了").tag(WordsShowOption.memorized)
                        }
                        Spacer()
                        Text("並び替え")
                            .font(.body)
                        Picker("", selection: $sortOption) {
                            Text("追加順(新)").tag(SortOption.latest)
                            Text("追加順(古)").tag(SortOption.oldest)
                            Text("アルファベット順").tag(SortOption.alphabet)
                        }
                    }
                })
                {
                    ForEach(filteredWords) { wordViewModel in
                            WordListRowView(path: $path, word: Binding(get: { wordViewModel }, set: { _ in }), showAllMeaning: $showAllMeaning, wordsShowOption: $wordsShowOption)
                                .contentShape(Rectangle())
                                .onChange(of: wordViewModel.isFavorite) {
                                    alertMessage = "更新中..."
                                    showLoadingAlert = true
                                    //お気に入りの変更があったら保存
                                    try! context.save()
                                    showLoadingAlert = false
                                }
                            // セルにスワイプすると編集ボタンが表示されます
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(action: {
                                        //確認のダイアログを表示
                                        wordViewModel_delete = wordViewModel
                                        showDeleteAlert = true
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                    Button(action: {
                                        wordViewModel_edit = wordViewModel
                                        showTagSheet = true
                                    }) {
                                        Label("Edit", systemImage: "rectangle.and.pencil.and.ellipsis")
                                    }
                                }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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
        .overlay(
            ZStack {
                if showLoadingAlert {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    CommonLoadingAlertView(alertMessage: $alertMessage)
                }
            }
        )
        .sheet(isPresented: $showTagSheet,
               onDismiss: {
            alertMessage = "更新中..."
            showLoadingAlert = true
            //編集が終わったら保存
            try! context.save()
            showLoadingAlert = false
            
        }
        ) {
            WordEditSheet(word: $wordViewModel_edit)
                .presentationDetents([.large])
                .onDisappear{
                    try! context.save()
                }
        }
        .sheet(isPresented: $showAddWordSheet)
        {
            AddWordFromListView(selectedTag: tag)
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert( title: Text("削除"), message: Text("本当に削除しますか？"), primaryButton: .destructive(Text("削除")) {
                alertMessage = "削除中..."
                showLoadingAlert = true
                //削除処理
                context.delete(wordViewModel_delete!)
                try! context.save()
                showLoadingAlert = false
            }, secondaryButton: .cancel()
            )
        }
        .navigationBarTitle(isAllWords ? "全ての単語": (tag?.name ?? "タグ未設定"))
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "検索")
    }
}

enum WordsShowOption {
    case all
    case favorite
    case memorized
}

enum SortOption {
    case latest
    case oldest
    case alphabet
}
