//
//  MainTab.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/07.
//

import SwiftUI

struct MainTab: View {
    @State var tabType: MainTabType = .quiz
    static var JSON: WordStoreService?
    static var TagJSON: TagStoreService?
    @State private var showLoadingAlert = false
    @State var alertMessage: String = ""
    @Environment(\.scenePhase) private var scenePhase

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
            MainTab.TagJSON = TagStoreService()
            showLoadingAlert = false
        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            if newScenePhase == .active {
                alertMessage = "読み込み中"
                showLoadingAlert = true
                if let json = MainTab.JSON{
                    json.loadJSON()
                }
                if let json = MainTab.TagJSON{
                    json.loadJSON()
                }
                showLoadingAlert = false
            }
        }

    }
}
