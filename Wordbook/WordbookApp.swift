//
//  WordbookApp.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/07.
//

import SwiftUI
import SwiftData

@main
struct WordbookApp: App {
    var body: some Scene {
        WindowGroup {
            MainTab()
        }
        .modelContainer(sharedModelContainer)
    }
}
