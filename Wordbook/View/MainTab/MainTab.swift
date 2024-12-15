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
    @State private var showLoadingAlert = false
    @State var alertMessage: String = ""

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

    }
}
