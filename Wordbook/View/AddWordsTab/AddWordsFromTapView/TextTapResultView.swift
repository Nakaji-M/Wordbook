//
//  TextTapResultView.swift
//  Wordbook
//
//  Created by Masanori on 2024/09/12.
//

import SwiftUI

struct TextTapResultView: View {
    @Binding var path: [Path]
    let tapItem: [TapItem]
    @State private var showLoadingAlert = false
    @State var recognitionResult: [WordStoreItem] = []
    @State var rowID: UUID?
    @State var alertMessage: String = ""
    @State private var selectedTag: Tag?
    @State var isFirstAppear: Bool = true

    var body: some View {
        List {
            Section(header:
                    //Tagを設定するためのページ
                    Button(action: {
                        path.append(.tagSelection($selectedTag))
                    }) {
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
            )
            {
                ForEach($recognitionResult) { $rowViewModel in
                    ResultsRow(viewModel: $rowViewModel)
                        .contentShape(Rectangle())
                    // セルにスワイプすると編集ボタンが表示されます
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(action: {
                                recognitionResult.removeAll { $0.id == rowViewModel.id }
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                            Button(action: {
                                rowID = rowViewModel.id
                            }) {
                                Label("Edit", systemImage: "rectangle.and.pencil.and.ellipsis")
                            }
                        }
                        .onTapGesture(perform: {
                            rowID = rowViewModel.id
                        })
                        .sheet(isPresented: Binding<Bool>(
                            get: { rowViewModel.id == rowID },
                            set: { _ in
                                rowID = nil
                            })
                        ) {
                            EditSheet(viewModel: $rowViewModel)
                                .presentationDetents([.large])
                        }
                }.onMove(perform: { indices, newOffset in
                    self.recognitionResult.move(fromOffsets: indices, toOffset: newOffset)
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .navigationTitle("認識結果")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    alertMessage = "保存中..."
                    showLoadingAlert = true
                    MainTab.JSON?.inserrtWords(words_add: recognitionResult.map({
                        let item = $0
                        item.tag = selectedTag?.id
                        return item
                    })
                    )
                    showLoadingAlert = false
                    path = []
                }) {
                    Label("保存", systemImage: "square.and.arrow.down")
                        .labelStyle(TitleOnlyLabelStyle())
                }
            }
        }
        .task {
            //タグ選択から戻ってきた時には表示しない
            //タグ選択から戻ってきた時には表示しない
            if isFirstAppear {
                alertMessage = "構成中..."
                showLoadingAlert = true
                let tapItem = self.tapItem
                let words = tapItem.filter({ $0.isWord })
                var meanings = tapItem.filter({ $0.isMeaning })
                meanings.sort(by: { $0.boundingBox.minY > $1.boundingBox.minY })
                let fontSize = meanings.reduce(0, { $0 + $1.boundingBox.height }) / CGFloat(meanings.count)
                for i in 0..<words.count {
                    let word = words[i]
                    var wordMeanings: [TapItem] = []
                    if meanings.count > 0 {
                        if i == words.count - 1 {
                            wordMeanings.append(contentsOf: meanings)
                        }
                        else {
                            while meanings.count > 0 {
                                if (meanings.first!.boundingBox.minY + meanings.first!.boundingBox.maxY)/2 > words[i + 1].boundingBox.maxY{
                                    wordMeanings.append(meanings.first!)
                                    meanings.removeFirst()
                                } else {
                                    break
                                }
                            }
                        }
                    }
                    recognitionResult.append(WordStoreItem(word: word.word, meaning: wordMeanings.map({ $0.word }).joined(separator: "\n")))
                }
                isFirstAppear = false
                showLoadingAlert = false
            }
        }
    }
}
