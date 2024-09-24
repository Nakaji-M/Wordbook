//
//  AddWordsFromTapView.swift
//  Wordbook
//
//  Created by Masanori on 2024/09/12.
//

import SwiftUI
import Vision

struct AddWordsFromTapView: View {
    @Binding var path: [Path]
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
                            y: (1 - word.boundingBox.midY) * geometry.size.height
                        )
                    }
                }
            }
            .aspectRatio(CGSize(width: uiImage.first!.size.width, height: uiImage.first!.size.height), contentMode: .fit)
        }
        .id(ZoomableContainerId)
        .task {
            let textRecognition = TextRecognition(uiImage: uiImage.first!, addWordsViewModel: AddWordsViewModel(), manualProcessViewModel: nil, exertScanExample: false, scanIdiom: false)
            try! await textRecognition.recognizeText()
            let orientation = uiImage.first!.imageOrientation
            let recognitionResult = textRecognition.recognizedTexts
            for result in recognitionResult {
                let boundingBox = textRecognition.fixBoundingBoxOrientation(bounds: result.boundingBox, orientation: orientation)
                self.tapItem.append(TapItem(word: result.topCandidates(1).first!.string, boundingBox: boundingBox))
            }
            ZoomableContainerId.toggle()
        }
        .navigationTitle("英単語の選択")
        .navigationBarItems(trailing: Button("次へ") {
            path = [.addFromTapMeanings(tapItem, uiImage)]
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
