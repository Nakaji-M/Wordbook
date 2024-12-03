//
//  MainTab.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/07.
//

import SwiftUI
import SwiftData

struct MainTab: View {
    @State var tabType: MainTabType = .quiz
    static var JSON: WordStoreService?
    @State private var showLoadingAlert = false
    @State var alertMessage: String = ""
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView(selection: $tabType) {

            QuizView()
                .tabItem {
                    Label("クイズ", systemImage: "pencil")
                }
                .tag(MainTabType.quiz)

            WordbookListView()
                .tabItem {
                    Label("単語リスト", systemImage: "list.dash.header.rectangle")
                }
                .tag(MainTabType.wordslist)

            AddWordsView()
                .tabItem {
                    Label("単語を追加", systemImage: "plus.circle")
                }
                .tag(MainTabType.addwords)
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
                .tag(MainTabType.settings)
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
        .onAppear{
            alertMessage = "読み込み中"
            showLoadingAlert = true
            MainTab.JSON = WordStoreService()
            for word in try! context.fetch(FetchDescriptor<Word>()){
                context.delete(word)
            }
            for word in MainTab.JSON!.getAllWords(){
                //swiftdata に保存
                let wordModel = Word(word: word.word, meaning: word.meaning)
                wordModel.id = word.id
                wordModel.isFavorite = word.isFavorite
                wordModel.isMemorized = word.isMemorized
                wordModel.example = word.example
                wordModel.note = word.note
                wordModel.tag = word.tag
                context.insert(wordModel)
            }
                
            showLoadingAlert = false
        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            if newScenePhase == .active {
                if let json = MainTab.JSON{
                    alertMessage = "読み込み中"
                    showLoadingAlert = true
                    json.loadJSON()
                    showLoadingAlert = false
                }
            }
        }

    }
}
