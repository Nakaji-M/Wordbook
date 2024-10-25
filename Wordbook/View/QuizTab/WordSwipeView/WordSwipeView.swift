//
//  WordsSwipeView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/29.
//

import SwiftUI

struct WordSwipeView: View {
    var isAllWords: Bool
    var tags: [Tag]
    var includeMemorized: Bool
    var includeNoTags: Bool
    @State private var words: [WordStoreItem] = []
    @State private var isFront = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack{
            Text("残り\(words.count)単語")
            ZStack{
                VStack{
                    Text("お疲れ様でした！  🎉🎉🎉")
                        .font(.title)
                        .padding(.bottom, 10)
                    Button("前の画面に戻る") {
                        dismiss()
                    }
                    .font(.title3)
                }
                GeometryReader { (proxy: GeometryProxy) in
                    StackSwipableCardView(self.words.prefix(3),
                                          cardContent: { (card: WordStoreItem) in
                        FlipView(isFront: (card.id == words.first?.id) ? self.isFront : true,
                                 duration: 0.5,
                                 front: {
                            HStack{
                                Text(card.word)
                                    .font(.title)
                                    .padding(.leading, 5)
                                SpeechUtteranceButton(text: Binding(get: { card.word }, set: { _ in }), rate: 0.5)
                            }
                            .frame(width: proxy.size.width - 16 * 2, height: proxy.size.height - 16 * 3, alignment: .center)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        },
                                 back: {
                            if card.meaning.isEmpty && !card.url.isEmpty, let url = URL(string: card.url) {
                                WebView(loardUrl: url)
                                    .frame(width: proxy.size.width - 16 * 2, height: proxy.size.height - 16 * 3, alignment: .center)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                            else {
                                Text(card.meaning)
                                    .font(.title)
                                    .frame(width: proxy.size.width - 16 * 2, height: proxy.size.height - 16 * 3, alignment: .center)
                                    .background(Color(UIColor.tertiarySystemBackground))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                        })
                        .onTapGesture {
                            if card.id == words.first?.id {
                                self.isFront.toggle()
                            }
                        }
                    },
                                          onEndedMove: { (card: WordStoreItem, translation: CGSize) in
                        switch translation.width {
                        case let w where w < -0.3 * proxy.size.width:
                            return .throwLeft
                        case let w where w > 0.3 * proxy.size.width:
                            return .throwRight
                        default:
                            return .none
                        }
                    },
                                          onThrowAway: { (card: WordStoreItem, action: CardViewEndedMoveAction) in
                        self.isFront = true
                        if action == .throwLeft {
                            //覚えていない
                            self.words.first?.isMemorized = false
                            MainTab.JSON?.updateWord(word_update: self.words.first!)
                        }
                        else if action == .throwRight {
                            //覚えている
                            self.words.first?.isMemorized = true
                            MainTab.JSON?.updateWord(word_update: self.words.first!)
                        }
                        self.words.removeAll(where: { $0.id == card.id })
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.all, 16)
                }
                .onFirstAppear {
                    if isAllWords {
                        words = MainTab.JSON?.getAllWords() ?? []
                    }
                    else{
                        for tag in tags{
                            words = words + (MainTab.JSON?.getWordsFromTag(tag: tag) ?? [])
                        }
                        if(includeNoTags){
                            words = words + (MainTab.JSON?.getWordsFromTag(tag: nil) ?? [])
                        }
                    }
                    if !includeMemorized{
                        words = words.filter({ !$0.isMemorized })
                    }
                }
            }
            
            HStack{
                VStack{
                    Image(systemName: "arrowshape.left.fill")
                    Text("覚えてない")
                }
                .padding(.all, 8)
                .background(Color.red, ignoresSafeAreaEdges: .top)
                .cornerRadius(3.0)
                Spacer()
                Text("カードをスワイプ！")
                    .multilineTextAlignment(.center)
                Spacer()
                VStack{
                    Image(systemName: "arrowshape.right.fill")
                    Text("覚えてた！")
                }
                .padding(.all, 8)
                .background(Color.green, ignoresSafeAreaEdges: .top)
                .cornerRadius(3.0)
            }
        }
    }
}
