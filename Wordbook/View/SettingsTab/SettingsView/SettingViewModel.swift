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
    @Published var scanIdiom: Bool = false
    @Published var llmModelExist: Bool = false
    @Published var llmModelSize: Int = 0
        
    init(){
        //UserDefaultsから設定を読み込む
        scanIdiom = settingsStoreService.loadBoolSetting(settingKey: .scanIdiom)
    }
    
    func loadLLMStatus() async{
        llmModelExist = await ModelFileManagement().checkDirectoryExist(modelConfiguration: ModelConfiguration.llama3_2_1B_4bit)
        if llmModelExist{
            llmModelSize = await ModelFileManagement().checkFileSize(modelConfiguration: ModelConfiguration.llama3_2_1B_4bit)
        }
    }
    
    func saveSetting(){
        //UserDefaultsに設定を保存
        settingsStoreService.saveBoolSetting(settingKey: .scanIdiom, value: scanIdiom)
    }
    
    func deleteLLMModel() throws{
        try ModelFileManagement().deleteDirectory(modelConfiguration: ModelConfiguration.llama3_2_1B_4bit)
    }
}
