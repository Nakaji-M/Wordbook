//
//  SettingsView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/07.
//

import SwiftUI

struct SettingsView: View {
    //ViewModel
    @StateObject var viewModel: SettingViewModel = SettingViewModel()
    @State private var showLoadingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $viewModel.scanIdiom) {
                        Label("熟語もスキャンする", systemImage: "doc.text")
                    }
                    .onChange(of: viewModel.scanIdiom) {
                        Task {
                            viewModel.saveSetting()
                        }
                    }

                } header: {
                    Text("スキャン設定")
                }
                
                Section {
                    Text("LLMを削除した場合でも機能使用時には再ダウンロードされます")
                    HStack {
                        Label("LLMの状態", systemImage: "info")
                        Spacer()
                        if viewModel.llmModelExist {
                            Text("デバイスに保存済み")
                        } else {
                            Text("デバイスに未保存")
                        }
                    }
                    
                    if viewModel.llmModelExist {
                        HStack {
                            Label("LLMのサイズ", systemImage: "info")
                            Spacer()
                            Text("\(viewModel.llmModelSize/1024/1024)MB")
                        }
                    }

                    Button(action: {
                        Task {
                            showLoadingAlert = true
                            alertMessage = "LLMを削除中"
                            try viewModel.deleteLLMModel()
                            await viewModel.loadLLMStatus()
                            showLoadingAlert = false
                        }
                    }) {
                        Label("LLMを削除", systemImage: "trash")
                    }
                    .disabled(!viewModel.llmModelExist)
                } header: {
                    Text("LLM設定")
                }
                
                Section {
                    NavigationLink(destination: WebReplaceListSettingsView()) {
                        Label("意味の自動入力時のフィルタリングリスト", systemImage: "textformat")
                    }
                } header: {
                    Text("ブラウザ共有設定")
                }
            }
            .overlay(
                ZStack {
                    if showLoadingAlert {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        LoadingAlert(alertMessage: $alertMessage)
                    }
                }
            )
            .task {
                await viewModel.loadLLMStatus()
            }
            .navigationBarTitle("設定")
        }
    }
}

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
