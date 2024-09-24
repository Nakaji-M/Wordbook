//
//  SwipableCardView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/29.
//

import SwiftUI

fileprivate struct SwipableCardView<Source, CardContent: View>: View {
    internal let source: Source
    internal let configuration: StackSwipableCardConfiguration
    internal let cardContent: (Source) -> CardContent
    internal let onEndedMove: (Source, CGSize) -> CardViewEndedMoveAction
    internal let onThrowAway: (Source) -> Void
    @State private var translation: CGSize = .zero

    public var body: some View {
        self.cardContent(source)
            .rotationEffect(configuration.calcRotation(translation), anchor: .bottom)
            .offset(x: translation.width, y: 0)
            .scaleEffect(configuration.calcScale())
            .offset(configuration.calcOffset())
            .gesture(gesture)
    }
    private var gesture: some Gesture {
        return DragGesture()
            .onChanged({ value in
                self.translation = value.translation
            })
            .onEnded({ value in
                let action = self.onEndedMove(self.source, value.translation)
                switch action {
                case .throwLeft:
                    withAnimation(.easeInOut(duration: self.configuration.threwLeft.duration), {
                        self.translation = self.configuration.threwLeft.point
                    })
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.configuration.threwLeft.duration) {
                        self.onThrowAway(self.source)
                    }
                case .throwRight:
                    withAnimation(.easeInOut(duration: self.configuration.threwRight.duration), {
                        self.translation = self.configuration.threwRight.point
                    })
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.configuration.threwRight.duration) {
                        self.onThrowAway(self.source)
                    }
                case .none:
                    self.translation = .zero
                }
            })
    }
}
