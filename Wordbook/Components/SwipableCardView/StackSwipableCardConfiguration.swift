//
//  StackSwipableCardConfiguration.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/29.
//

import SwiftUI

public struct StackSwipableCardConfiguration {
    /// stackされたviewの小さくなる倍率
    public let calcScale: () -> CGFloat
    /// stackされたviewがずれる割合
    public let calcOffset: () -> CGSize
    /// 移動量に応じた回転量
    public let calcRotation: (_ translation: CGSize) -> Angle
    /// 左右に飛んでいった先の位置
    public let threwLeft: (point: CGSize, duration: Double)
    public let threwRight: (point: CGSize, duration: Double)
}

//CardViewEndedMoveAction
public enum CardViewEndedMoveAction {
    case none
    case throwLeft
    case throwRight
}
