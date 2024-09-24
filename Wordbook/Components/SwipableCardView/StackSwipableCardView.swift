//
//  StackSwipableCardView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/29.
//

import SwiftUI

public struct StackSwipableCardView<Sources: RandomAccessCollection, CardContent: View> : View where Sources.Element : Identifiable {
    private let sources: Sources
    private let cardContent: (Sources.Element) -> CardContent
    private let onEndedMove: (Sources.Element, CGSize) -> CardViewEndedMoveAction
    private let onThrowAway: (Sources.Element, CardViewEndedMoveAction) -> Void
    private var configuration: StackSwipableCardConfiguration? = nil
    public init(_ sources: Sources,
                @ViewBuilder cardContent: @escaping (Sources.Element) -> CardContent,
                             onEndedMove: @escaping (Sources.Element, CGSize) -> CardViewEndedMoveAction,
                             onThrowAway: @escaping (Sources.Element, CardViewEndedMoveAction) -> Void,
                             configuration: StackSwipableCardConfiguration? = nil) {
        self.sources = sources
        self.cardContent = cardContent
        self.onEndedMove = onEndedMove
        self.onThrowAway = onThrowAway
        self.configuration = configuration
    }
    public var body: some View {
        GeometryReader { (proxy: GeometryProxy) in
            ZStack {
                ForEach(Array(self.sources.reversed().enumerated()), id: \.1.id) { (i: Int, source: Sources.Element) in
                    SwipableCardView(source: source,
                                     configuration: self.configuration ?? .makeDefault(sourcesSize: self.sources.count, index: i, proxy: proxy),
                                     cardContent: self.cardContent,
                                     onEndedMove: self.onEndedMove,
                                     onThrowAway: self.onThrowAway)
                }
                .animation(.spring())
            }
        }
    }
}


//Make Default
extension StackSwipableCardConfiguration {
    static func makeDefault(sourcesSize: Int, index: Int, proxy: GeometryProxy) -> StackSwipableCardConfiguration {
        let calcScale: () -> CGFloat = {
            let scale = CGFloat(1.0 - 0.02 * Double(index))
            return scale
        }
        let calcOffset: () -> CGSize = {
            let offset = CGSize(width: 0, height: CGFloat(10 * index))
            return offset
        }
        let calcRotation: (_ translation: CGSize) -> Angle = { translation in
            let rotation = Angle(degrees: Double(translation.width) / 20)
            return rotation
        }
        let threwLeft: (point: CGSize, duration: Double) = (point: CGSize(width: -proxy.size.width, height: 0), duration: 0.3)
        let threwRight: (point: CGSize, duration: Double) = (point: CGSize(width: proxy.size.width, height: 0), duration: 0.3)
        return StackSwipableCardConfiguration(calcScale: calcScale,
                                              calcOffset: calcOffset,
                                              calcRotation: calcRotation,
                                              threwLeft: threwLeft,
                                              threwRight: threwRight)
    }
}


fileprivate struct SwipableCardView<Source, CardContent: View>: View {
    internal let source: Source
    internal let configuration: StackSwipableCardConfiguration
    internal let cardContent: (Source) -> CardContent
    internal let onEndedMove: (Source, CGSize) -> CardViewEndedMoveAction
    internal let onThrowAway: (Source, CardViewEndedMoveAction) -> Void
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
                        self.onThrowAway(self.source, .throwLeft)
                    }
                case .throwRight:
                    withAnimation(.easeInOut(duration: self.configuration.threwRight.duration), {
                        self.translation = self.configuration.threwRight.point
                    })
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.configuration.threwRight.duration) {
                        self.onThrowAway(self.source, .throwRight)
                    }
                case .none:
                    self.translation = .zero
                }
            })
    }
}

