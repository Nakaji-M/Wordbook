//
//  ShareViewController.swift
//  ShareToWordbook
//
//  Created by Masanori on 2024/08/30.
//

import UIKit
import UniformTypeIdentifiers
import SwiftUI

class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Ensure access to extensionItem and itemProvider
        guard
            let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let itemProvider = extensionItem.attachments?.first else {
            print("Error: Could not access extension item or item provider")
            close()
            return
        }
        

        // Check type identifier
            
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier){
            itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { data, error in
                let dictionary = data as! NSDictionary
                OperationQueue.main.addOperation {
                    let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as! NSDictionary
                    
                    let title = results["title"] as! String
                    let url = results["url"] as! String
                    let meaning = results["selected"] as! String
                    let keywords = results["keywords"] as! String
                    let description = results["description"] as! String

                    DispatchQueue.main.async {
                        // host the SwiftU view
                        let contentView = UIHostingController(rootView: ShareExtensionView(url: url, title: title, meaning: meaning, keywords: keywords, description: description))
                        self.addChild(contentView)
                        self.view.addSubview(contentView.view)
                        
                        // set up constraints
                        contentView.view.translatesAutoresizingMaskIntoConstraints = false
                        contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                        contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
                        contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                        contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
                    }
                }
            }
                    } else {
                        self.close()
                        return
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.close()
            }
        }
    }
    /// Close the Share Extension
    func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
}
