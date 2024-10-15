//
//  QuizView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/07.
//

import SwiftUI
import SwiftData

struct QuizView: View {
    struct PickerSelection: Hashable{
        var Tags: [Tag]
        var isAllWords: Bool
        var includeNoTags: Bool
    }
    
    @State private var pickerSelection = PickerSelection(Tags: [], isAllWords: true, includeNoTags: false)
    @State private var includeMemorized = false
    @Query(sort: \Tag.name) private var tags: [Tag] = []
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading){
                Form {
                    Toggle(isOn: $includeMemorized){
                        Text("覚えた単語を含む")
                    }
                    
                    Section{
                        Button(action: {
                            withAnimation {
                                self.pickerSelection.isAllWords.toggle()
                            }
                        })
                        {
                            HStack {
                                Image(systemName: "checkmark")
                                    .opacity(self.pickerSelection.isAllWords ? 1.0 : 0.0)
                                Text("全て")
                            }
                        }
                        Button(action: {
                            withAnimation {
                                self.pickerSelection.includeNoTags.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                    .opacity(self.pickerSelection.includeNoTags ? 1.0 : 0.0)
                                Text("タグ未設定")
                            }
                        }
                        .foregroundColor(.primary)
                        ForEach(tags) { item in
                            Button(action: {
                                withAnimation {
                                    if self.pickerSelection.Tags.contains(item) {
                                        // Previous comment: you may need to adapt this piece
                                        self.pickerSelection.Tags.removeAll(where: { $0 == item })
                                    } else {
                                        self.pickerSelection.Tags.append(item)
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark")
                                        .opacity(self.pickerSelection.Tags.contains(item) ? 1.0 : 0.0)
                                    Text(item.name)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    } header : {
                        Text("出題するタグ")
                            .font(.headline)
                    }
                }.padding(.bottom)
                
                NavigationLink(destination: WordsSwipeView(isAllWords: pickerSelection.isAllWords, tags: pickerSelection.Tags, includeMemorized: includeMemorized, includeNoTags: pickerSelection.includeNoTags)){
                    HStack {
                        VStack(alignment: .leading, spacing: 8){
                            Text("START QUIZ")
                                .padding()
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }.padding(.all)
                }
                
                Spacer()

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.listBackground))
            .navigationBarTitle("クイズ")
        }
    }
}
