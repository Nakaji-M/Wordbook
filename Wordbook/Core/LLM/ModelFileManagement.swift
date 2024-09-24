//
//  ModelFileManagement.swift
//  Wordbook
//
//  Created by Masanori on 2024/09/02.
//

import Foundation
@preconcurrency import Hub
import MLXLLM

class ModelFileManagement{
    let hub: HubApi = HubApi()
    
    private func getDirectoryURL(modelConfiguration: ModelConfiguration) -> URL {
        let directoryURL = modelConfiguration.modelDirectory(hub: hub)
        return directoryURL
    }
    
    func deleteDirectory(modelConfiguration: ModelConfiguration) throws {
        let directoryURL = modelConfiguration.modelDirectory(hub: hub)
        try FileManager.default.removeItem(at: directoryURL)
    }
    
    func checkDirectoryExist(modelConfiguration: ModelConfiguration) async -> Bool {
        let directoryURL = modelConfiguration.modelDirectory(hub: hub)
        return FileManager.default.fileExists(atPath: directoryURL.path)
    }
    
    func checkFileSize(modelConfiguration: ModelConfiguration) async -> Int {
        let directoryURL = modelConfiguration.modelDirectory(hub: hub)
        let fileManager = FileManager.default
        let files = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        var totalSize = 0
        if let files = files {
            for file in files {
                let attr = try? fileManager.attributesOfItem(atPath: file.path)
                if let attr = attr {
                    totalSize += attr[FileAttributeKey.size] as! Int
                }
            }
        }
        return totalSize
    }
}
