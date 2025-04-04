//
//  WordsListRow.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/26.
//

import SwiftUI

struct WordListRowView: View {
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
