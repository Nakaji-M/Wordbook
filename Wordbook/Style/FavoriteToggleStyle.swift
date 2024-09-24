//
//  FavoriteToggleStyle.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/24.
//

import SwiftUI

struct FavoriteToggleStyle: ToggleStyle {

    static let backgroundColor = Color(.label)
    static let switchColor = Color(.systemBackground)

    func makeBody(configuration: Configuration) -> some View {

        VStack {
            Image(systemName: configuration.isOn ? "heart.fill": "heart")
                .resizable()
                .frame(width: 25, height: 25)
                .font(.system(size: 50))
                .opacity(configuration.isOn ? 1 : 0.7)
            .onTapGesture(perform: {
                configuration.isOn.toggle()
            })

            configuration.label

        }

    }

}
