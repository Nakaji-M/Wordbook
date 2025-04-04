//
//  AddWordsFromTapView.swift
//  Wordbook
//
//  Created by Masanori on 2024/09/12.
//

import SwiftUI
import Vision

struct AddWordsFromTapView: View {
    @Binding var path: [AddWordsPath]
    @State var tapItem: [TapItem] = []
    @State var ZoomableContainerId: Bool = false
    let uiImage: [UIImage]
    
    var body: some View {
        ZoomableContainer{
            GeometryReader{ geometry in
                ZStack{
                    Image(uiImage: uiImage.first!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    ForEach(tapItem, id: \.uuid) { word in
                        Toggle(isOn: $tapItem[tapItem.firstIndex(where: { $0.uuid == word.uuid })!].isWord) {
                            let text = Text(word.word)
                                .lineLimit(1)
                                .bold()
                                .font(.system(size: 100))
                                .minimumScaleFactor(0.01)
                                .frame(width: word.boundingBox.width * geometry.size.width, height: word.boundingBox.height * geometry.size.height)
                            if word.isWord {
                                text.foregroundColor(.white)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.blue)
                                    )
                            }else {
                                text
                                    .foregroundColor(.blue)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(UIColor.lightGray))
                                    )
                            }
                        }
                        .tint(Color.clear)
                        .toggleStyle(.button)
                        .position(
                            x: word.boundingBox.midX * geometry.size.width,
                            y: word.boundingBox.midY * geometry.size.height
                        )
                    }
                }
            }
            .aspectRatio(CGSize(width: uiImage.first!.size.width, height: uiImage.first!.size.height), contentMode: .fit)
        }
        .id(ZoomableContainerId)
        .task {
            do{
                let ocr = OCR(uiImage: uiImage.first!)
                let recognitionResult = try await ocr.recognize()
                for result in recognitionResult {
                    self.tapItem.append(TapItem(word: result.text, boundingBox: result.box))
                }
            }catch{
                
            }
            ZoomableContainerId.toggle()
        }
        .navigationTitle("英単語の選択")
        .navigationBarItems(trailing: Button("次へ") {
            path = [.addFromTapMeanings(tapItem: tapItem, uiImage: uiImage)]
        })
    }
}

class TapItem{
    var word: String
    var boundingBox: CGRect
    let uuid = UUID()
    var isWord: Bool = false
    var isMeaning: Bool = false
    init(word: String, boundingBox: CGRect) {
        self.word = word
        self.boundingBox = boundingBox
    }
}
