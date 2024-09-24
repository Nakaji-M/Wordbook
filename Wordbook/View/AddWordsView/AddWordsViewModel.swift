//
//  AddWordsViewModel.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/08.
//

import Foundation

public class AddWordsViewModel: ObservableObject {
    @Published var ocrProcessSelection: OCRProcessSelection = .dismiss
    @Published var isGenerateExample: Bool = false
    @Published var isMeaningFromDictionary: Bool = false
}

public enum OCRProcessSelection {
    case dismiss
    case auto
    case manual
}
