//
//  ManualProcessViewModel.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/11.
//

import Foundation

class ManualProcessSelectionViewModel: ObservableObject {
    @Published  var whereIsMeaning: MeaningPosition = .below
    @Published  var isManualWordsPerPage = false
    var wordsPerPage = 0
    @Published var wordsPerPageString = "" {
        didSet {
            let numeralsOnlyInput = wordsPerPageString.allSatisfy { $0.isNumber } // 数字以外は受け付けない
            if numeralsOnlyInput {
                self.wordsPerPage = Int(wordsPerPageString) ?? 0
            }
            else{
                self.wordsPerPageString = oldValue
            }
        }
    }
}

enum MeaningPosition {
    case right
    case top
    case below
}
