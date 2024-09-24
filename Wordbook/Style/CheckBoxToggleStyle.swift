//
//  CheckBoxToggleStyle.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/23.
//

import SwiftUI

struct CheckBoxToggleStyle:ToggleStyle{
    func makeBody(configuration: Configuration) -> some View {
        Button{
            configuration.isOn.toggle()
        } label: {
            HStack{
                configuration.label
                Spacer()
                Image(systemName: configuration.isOn
                      ? "checkmark.circle.fill"
                      : "circle")
            }
        }
    }
}
