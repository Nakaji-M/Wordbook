//
//  SpeechUtteranceButton.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/30.
//

import SwiftUI
import AVFoundation


struct SpeechUtteranceButton: View {
    @Binding var text: String
    var rate: Float
    let speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        Button(action: {
            speak()
        }) {
            Image(systemName: "speaker.3")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
    }
      
    func speak() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback,mode: .default)

        } catch let error {
            print("This error message from SpeechSynthesizer \(error.localizedDescription)")
        }
        
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: text)
        //speechUtterance.rate = rate
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(speechUtterance)
    }
}
