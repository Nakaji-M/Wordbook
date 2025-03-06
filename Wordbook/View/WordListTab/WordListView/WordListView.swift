//
//  WordsListView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/22.
//

import SwiftUI
import Translation

struct WordListView: View {
    var isAllWords: Bool
    var tag: TagStoreItem?
    @Binding var path: [WordListPath]
    @State private var searchText: String = ""

    var body: some View {
        WordListContentView(isAllWords: isAllWords, tag: tag, path: $path, searchText: $searchText)
        .navigationBarTitle(isAllWords ? "全ての単語": (tag?.name ?? "タグ未設定"))
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "検索")
    }
}

struct WordListContentView: View {
    var isAllWords: Bool
    var tag: TagStoreItem?
    @Binding var path: [WordListPath]
    @State var words: [WordStoreItem] = []
    @State private var showLoadingAlert = false
    @State var alertMessage: String = ""
    @State private var showDeleteAlert = false
    @State var wordViewModel_delete: WordStoreItem?
    @State private var showTagSheet = false
    @State var wordViewModel_edit: WordStoreItem = WordStoreItem()
    @State var showAllMeaning: Bool = false
    @State var wordsShowOption: WordsShowOption = .all
    @Binding var searchText: String
    @State private var sortOption: SortOption = .latest
    @State private var showAddWordSheet: Bool = false
    
    func matchWord(word: WordStoreItem, searchText: String) -> Bool {
        return word.word.lowercased().contains(searchText.lowercased()) || word.meaning.lowercased().contains(searchText.lowercased())
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
                    ForEach($words) { $wordViewModel in
                        if searchText.isEmpty || matchWord(word: wordViewModel, searchText: searchText) {
                            WordListRowView(path: $path, viewModel: $wordViewModel, showAllMeaning: $showAllMeaning, wordsShowOption: $wordsShowOption)
                                .contentShape(Rectangle())
                                .onChange(of: wordViewModel.isFavorite) {
                                    alertMessage = "更新中..."
                                    showLoadingAlert = true
                                    //お気に入りの変更があったらJSONに保存
                                    MainTab.JSON?.updateWord(word_update: wordViewModel)
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
            //編集が終わったらJSONに保存
            MainTab.JSON?.updateWord(word_update: wordViewModel_edit)
            if !isAllWords {
                words = words.filter { $0.tag == tag?.id }
            }
            showLoadingAlert = false
            
        }
        ) {
            WordEditSheet(viewModel: $wordViewModel_edit)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showAddWordSheet)
        {
            AddWordFromListView(onAdd: {word in
                addWord_sortOption(word: word)
                
            }, selectedTag: tag)
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert( title: Text("削除"), message: Text("本当に削除しますか？"), primaryButton: .destructive(Text("削除")) {
                alertMessage = "削除中..."
                showLoadingAlert = true
                //削除処理
                words.removeAll { $0.id == wordViewModel_delete!.id }
                //JSONからも削除
                MainTab.JSON?.deleteWord(word_delete: wordViewModel_delete!)
                showLoadingAlert = false
            }, secondaryButton: .cancel()
            )
        }
        .task{
            alertMessage = "読み込み中..."
            showLoadingAlert = true
            words = getWord_sortOption(sortOption: sortOption)
            showLoadingAlert = false
        }
        .onChange(of: sortOption){
            words = getWord_sortOption(sortOption: sortOption)
        }
    }
    
    func addWord_sortOption(word: WordStoreItem) {
        switch sortOption {
        case .latest:
            words.insert(word, at: 0)
        case .oldest:
            words.append(word)
        case .alphabet:
            let index = words.firstIndex(where: { $0.word.lowercased() > word.word.lowercased() }) ?? words.endIndex
            words.insert(word, at: index)
        }
    }
    
    func getWord_sortOption(sortOption: SortOption) -> [WordStoreItem] {
        var words: [WordStoreItem] = []
        if isAllWords {
            words = MainTab.JSON?.getAllWords() ?? []
        }
        else{
            words = MainTab.JSON?.getWordsFromTag(tag: tag) ?? []
        }
        switch sortOption {
        case .latest:
            return words.reversed()
        case .oldest:
            return words
        case .alphabet:
            return words.sorted(by: { $0.word.lowercased() < $1.word.lowercased() })
        }
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
