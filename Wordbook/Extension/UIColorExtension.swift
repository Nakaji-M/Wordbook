//
//  UIColorExtension.swift
//  Wordbook
//
//  Created by Masanori on 2024/09/04.
//

import Foundation
import UIKit

extension UIColor {
    static let listBackground = UIColor { (traitCollection: UITraitCollection) -> UIColor in
        if traitCollection.userInterfaceStyle == .dark {
            return UIColor.systemBackground
        } else {
            return UIColor.secondarySystemBackground
        }
    }
}
