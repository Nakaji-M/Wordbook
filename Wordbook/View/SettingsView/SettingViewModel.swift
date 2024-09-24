//
//  SettingViewModel.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/22.
//

import Foundation
import MLXLLM

@MainActor
class SettingViewModel: ObservableObject{
    private let settingsStoreService = SettingsStoreService()
    @Published var exertScanExample: Bool = false
    @Published var scanIdiom: Bool = false
    @Published var llmModelExist: Bool = false
    @Published var llmModelSize: Int = 0
        
    init(){
        //UserDefaultsから設定を読み込む
        exertScanExample = settingsStoreService.loadBoolSetting(settingKey: .exertScanExample)
        scanIdiom = settingsStoreService.loadBoolSetting(settingKey: .scanIdiom)
    }
    
    func loadLLMStatus() async{
        llmModelExist = await ModelFileManagement().checkDirectoryExist(modelConfiguration: ModelConfiguration.qwen205b4bit)
        if llmModelExist{
            llmModelSize = await ModelFileManagement().checkFileSize(modelConfiguration: ModelConfiguration.qwen205b4bit)
        }
    }
    
    func saveSetting(){
        //UserDefaultsに設定を保存
        settingsStoreService.saveBoolSetting(settingKey: .exertScanExample, value: exertScanExample)
        settingsStoreService.saveBoolSetting(settingKey: .scanIdiom, value: scanIdiom)
    }
    
    func deleteLLMModel() throws{
        try ModelFileManagement().deleteDirectory(modelConfiguration: ModelConfiguration.qwen205b4bit)
    }
}
