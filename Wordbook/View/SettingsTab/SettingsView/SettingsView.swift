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
                        CommonLoadingAlertView(alertMessage: $alertMessage)
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
