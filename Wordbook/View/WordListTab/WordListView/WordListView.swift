//
//  WordsListView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/22.
//

import SwiftUI
import SwiftData
import Translation

struct WordListView: View {
    var isAllWords: Bool
    var tag: Tag?
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
    @State private var searchText: String = ""
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
                            WordsListRow(path: $path, viewModel: $wordViewModel, showAllMeaning: $showAllMeaning, wordsShowOption: $wordsShowOption)
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
        .navigationBarTitle(isAllWords ? "全ての単語": (tag?.name ?? "タグ未設定"))
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "検索")
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


struct WordsListRow: View {
    @Binding var path: [WordListPath]
    @Binding var viewModel: WordStoreItem
    @Binding var showAllMeaning: Bool
    @Binding var wordsShowOption: WordsShowOption
    @State private var showThisMeaning = false
    @State private var showWebView = false
    @State private var showExampleTranslation = false
    
    var body: some View {
        if (wordsShowOption == .favorite && !viewModel.isFavorite) || (wordsShowOption == .memorized && viewModel.isMemorized) {
            return AnyView(EmptyView())
        }
        else{
            return AnyView(
                VStack(alignment: .leading, spacing: 8){
                    HStack{
                        Toggle(isOn: $viewModel.isFavorite){
                        }
                        .toggleStyle(FavoriteToggleStyle())
                        Text(viewModel.word)
                            .font(.headline)
                        Spacer()
                        SpeechUtteranceButton(text: $viewModel.word, rate: 0.5)
                    }
                    if !viewModel.url.isEmpty, let url = URL(string: viewModel.url) {
                        Button(action: {
                            showWebView.toggle()
                        }) {
                            Label("Webで意味を確認", systemImage: "safari")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                        .sheet(isPresented: $showWebView) {
                            WebView(loardUrl: url)
                        }
                    }
                        Button(action: {
                            showThisMeaning.toggle()
                        }){
                            VStack(alignment: .leading, spacing: 8){
                                if viewModel.relatedWords.count > 0 {
                                    HStack{
                                        Image(systemName: "link")
                                            .font(.subheadline)
                                        Button(action: {
                                            path.append(.relatedWord(originalWord: viewModel))
                                        })
                                        {
                                            VStack(alignment: .leading){
                                                ForEach(viewModel.relatedWords) { relatedWord in
                                                    HStack{
                                                        Text(relatedWord.word)
                                                        Spacer()
                                                            .frame(maxWidth: 8)
                                                        Text(relatedWord.meaning)
                                                        Spacer()
                                                    }
                                                }
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                HStack{
                                    Label(viewModel.meaning, systemImage: "pencil")
                                        .frame(alignment: .leading)
                                    Spacer()
                                }
                                if viewModel.example != "" {
                                    HStack{
                                        Label(viewModel.example, systemImage: "text.bubble")
                                            .translationPresentation(isPresented: $showExampleTranslation, text: viewModel.example)
                                            .frame(alignment: .leading)
                                        Spacer()
                                        Button(action: {
                                            showExampleTranslation.toggle()
                                        }) {
                                            Image(systemName: "translate")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                                if viewModel.note != "" {
                                    HStack{
                                        Label(viewModel.note, systemImage: "note.text")
                                            .frame(alignment: .leading)
                                        Spacer()
                                    }
                                }
                                
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                        }
                        .foregroundStyle(.primary)
                        .opacity(showAllMeaning || showThisMeaning ? 1 : 0)
                        .overlay{
                            if !(showAllMeaning || showThisMeaning) {
                                Text("タップして意味を表示")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        showThisMeaning.toggle()
                                    }
                        }
                    }
                }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical)
                    .sensoryFeedback(.selection, trigger: viewModel.isFavorite)
            )
        }
    }
}

// 編集画面
struct WordEditSheet: View {
    @Query var tags: [Tag] = []
    @Binding var viewModel: WordStoreItem
    @State var selectedTag: Tag?
    @State var showLoadingAlert: Bool = false //実質使用していない
    @State var alertMessage: String = "" //実質使用していない
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack{
            ScrollView{
                VStack(alignment: .leading, spacing: 8){
                    NavigationLink(destination:
                        CommonTagSelectionView(selectedTag: $selectedTag)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("完了") {
                                    dismiss()
                                }
                            }
                        }
                    )
                    {
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

                    CommonWordEditView(viewModel: $viewModel)
                }
                .padding(.all)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .navigationBarTitle("単語の編集")
        }
        .onChange(of: selectedTag) {
            viewModel.tag = selectedTag?.id
        }
        .onAppear {
            if let id = viewModel.tag {
                selectedTag = getTagfromId(id: id)
            }
            else {
                selectedTag = nil
            }
        }
    }
    
    func getTagfromId(id: UUID) -> Tag? {
        return tags.first(where: { $0.id == id })
    }
}

struct AddWordFromListView: View {
    let onAdd: (WordStoreItem) -> Void
    //入力された英単語
    @State var viewModel = WordStoreItem(word: "", meaning: "", example: "", note: "", isMemorized: false, isFavorite: false)
    //選択されたタグ
    @State var selectedTag: Tag?
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
