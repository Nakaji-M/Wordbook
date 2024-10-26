//
//  AddMeaningsFromTapView.swift
//  Wordbook
//
//  Created by Masanori on 2024/09/12.
//

import SwiftUI

struct AddMeaningsFromTapView: View {
    @Binding var path: [AddWordsPath]
    @State var tapItem: [TapItem]
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
                        Toggle(isOn: $tapItem[tapItem.firstIndex(where: { $0.uuid == word.uuid })!].isMeaning) {
                            let text = Text(word.word)
                                .lineLimit(1)
                                .bold()
                                .font(.system(size: 100))
                                .minimumScaleFactor(0.01)
                                .frame(width: word.boundingBox.width * geometry.size.width, height: word.boundingBox.height * geometry.size.height)
                            if word.isMeaning {
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
        .navigationTitle("意味の選択")
        .navigationBarItems(trailing: Button("次へ") {
            path = [.tapResult(tapItem: tapItem)]
        })
    }
}

