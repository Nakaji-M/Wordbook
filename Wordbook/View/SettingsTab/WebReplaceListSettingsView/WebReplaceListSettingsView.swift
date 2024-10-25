//
//  WebReplaceListSettingsView.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/25.
//

import SwiftUI

struct WebReplaceListSettingsView: View {
    @State private var webReplaceList: [String] = []
    @State private var newString: String = ""
    @State private var showInputModal = false
    let settingsStore = SettingsStoreService()
    
    var body: some View {
        List {
            ForEach($webReplaceList, id: \.self) { $replace in
                TextField("文字列を入力", text: $replace, axis: .vertical)
                    .onChange(of: replace) {
                        settingsStore.saveStringListSetting(settingKey: .webReplaceList, value: webReplaceList)
                    }
            }
            .onDelete {indexSet in
                webReplaceList.remove(atOffsets: indexSet)
                settingsStore.saveStringListSetting(settingKey: .webReplaceList, value: webReplaceList)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showInputModal = true
                }) {
                    Label("追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showInputModal, onDismiss: {
            if (self.newString != "") {
                self.webReplaceList.append(self.newString)
                settingsStore.saveStringListSetting(settingKey: .webReplaceList, value: self.webReplaceList)
                self.newString = ""
            }
        }) {
            AddWebReplaceItemView(text: $newString)
        }
        .onAppear() {
            webReplaceList = settingsStore.loadStringListSetting(settingKey: .webReplaceList)
        }
    }
}

struct AddWebReplaceItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            Spacer()
            Text("除去する文字列を入力")
            TextField("文字列", text: $text, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    self.text = ""
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("キャンセル")
                }
                Spacer()
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("OK")
                }
                .disabled(text.count == 0)
                Spacer()
            }
        }
        .padding()
    }
}
