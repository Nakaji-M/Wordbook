//
//  SettingsStoreService.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/22.
//

import Foundation

class SettingsStoreService {
    let appGroupId = "group.wordbook.common"

    enum SettingKey: String {
        case scanIdiom = "scanIdiom"
        case webReplaceList = "webReplaceList"
    }
    
    func loadBoolSetting(settingKey: SettingKey) -> Bool {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        if let userDefaults = userDefaults {
            return userDefaults.bool(forKey: settingKey.rawValue)
        }
        //デフォルト値
        if settingKey == .scanIdiom {
            return true
        }else{
            return false
        }
    }
    
    func saveBoolSetting(settingKey: SettingKey, value: Bool) {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        if let userDefaults = userDefaults {
            userDefaults.set(value, forKey: settingKey.rawValue)
        }
    }
    
    func loadStringListSetting(settingKey: SettingKey) -> [String] {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        if let userDefaults = userDefaults {
            return userDefaults.stringArray(forKey: settingKey.rawValue) ?? []
        }
        return []
    }
    
    func saveStringListSetting(settingKey: SettingKey, value: [String]) {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        if let userDefaults = userDefaults {
            userDefaults.set(value, forKey: settingKey.rawValue)
        }
    }
}
