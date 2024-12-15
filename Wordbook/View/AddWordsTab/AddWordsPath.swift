//
//  Path.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/25.
//

import SwiftUI

enum AddWordsPath: Hashable, Equatable {
    case addFromAuto(uiImages: [UIImage], ocrOption: OCROption)
    case tagSelection(selectedTag: Binding<TagStoreItem?>)
    case addFromText
    case addFromTap(uiImage: [UIImage])
    case addFromTapMeanings(tapItem: [TapItem], uiImage: [UIImage])
    case tapResult(tapItem: [TapItem])
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
    
    static func == (lhs: AddWordsPath, rhs: AddWordsPath) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    private var rawValue: Int {
        switch self {
            case .addFromAuto:
                return 0
            case .tagSelection:
                return 1
            case .addFromText:
                return 2
            case .addFromTap:
                return 3
            case .addFromTapMeanings:
                return 4
            case .tapResult:
                return 5
        }
    }
}
