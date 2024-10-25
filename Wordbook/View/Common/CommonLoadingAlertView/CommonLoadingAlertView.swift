//
//  CommonLoadingAlertView.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/25.
//

import SwiftUI

struct CommonLoadingAlertView: View {
    @Binding var alertMessage: String
        var body: some View {
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text(alertMessage)
                    .font(.headline)
            }
            .padding(30)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
            .shadow(radius: 10)
        }
    }
