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
        var Tag: Tag?
        var isAllWords: Bool
    }
    
    @State private var pickerSelection = PickerSelection(Tag: nil, isAllWords: true)
    @State private var includeMemorized = false
    @Query private var tags: [Tag] = []
    
    var body: some View {
        NavigationStack {
            VStack{
                
                Spacer()
                
                Toggle(isOn: $includeMemorized){
                    Text("覚えた単語を含む")
                }.padding(.all)
                
                HStack{
                    Text("出題するタグ")
                    Spacer()
                    Picker("Tag", selection: $pickerSelection) {
                        Text("全て").tag(PickerSelection(Tag: nil, isAllWords: true))
                        Text("タグ未設定").tag(PickerSelection(Tag: nil, isAllWords: false))
                        ForEach(tags) { tag in
                            Text(tag.name).tag(PickerSelection(Tag: tag, isAllWords: false))
                        }
                    }
                }.padding(.all)
                
                Spacer()
                Spacer()
                
                NavigationLink(destination: WordsSwipeView(isAllWords: pickerSelection.isAllWords, tag: pickerSelection.Tag, includeMemorized: includeMemorized)){
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
