//
//  Path.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/25.
//

import SwiftUI

enum Path: Hashable, Equatable {
    case textRecognitionResult([UIImage], OCROption)
    case tagSelection(Binding<Tag?>)
    case addFromText
    case addFromTap([UIImage])
    case addFromTapMeanings([TapItem], [UIImage])
    case tapResult([TapItem])
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
    
    static func == (lhs: Path, rhs: Path) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    private var rawValue: Int {
        switch self {
            case .textRecognitionResult:
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
