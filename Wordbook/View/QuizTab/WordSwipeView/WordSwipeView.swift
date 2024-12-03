//
//  WordsSwipeView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/29.
//

import SwiftUI
import SwiftData

struct WordSwipeView: View {
    var isAllWords: Bool
    var tags: [Tag]
    var includeMemorized: Bool
    var includeNoTags: Bool
    var filteredWords: [Word] {
        let filteredItems = words.compactMap { item in
            return (includeMemorized || item.isMemorized) && (tags.contains{$0.id == item.tag} || includeNoTags && item.tag == nil || isAllWords) && !doneWords.contains(item) ? item : nil
        }
        return filteredItems

    }
    @Query var words: [Word]
    @State private var doneWords: [Word] = []
    @State private var isFront = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    var body: some View {
        VStack{
            Text("残り\(filteredWords.count)単語")
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
                    StackSwipableCardView(self.filteredWords.prefix(3),
                                          cardContent: { (card: Word) in
                        FlipView(isFront: (card.id == filteredWords.first?.id) ? self.isFront : true,
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
                            if card.id == filteredWords.first?.id {
                                self.isFront.toggle()
                            }
                        }
                    },
                                          onEndedMove: { (card: Word, translation: CGSize) in
                        switch translation.width {
                        case let w where w < -0.3 * proxy.size.width:
                            return .throwLeft
                        case let w where w > 0.3 * proxy.size.width:
                            return .throwRight
                        default:
                            return .none
                        }
                    },
                                          onThrowAway: { (card: Word, action: CardViewEndedMoveAction) in
                        self.isFront = true
                        let wrd = filteredWords.first!
                        doneWords.append(wrd)
                        if action == .throwLeft {
                            //覚えていない
                            wrd.isMemorized = false
                        }
                        else if action == .throwRight {
                            //覚えている
                            wrd.isMemorized = true
                        }
                        wrd.lastLearned = Date()
                        try! context.save()
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.all, 16)
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
