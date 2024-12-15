//
//  CommonTagSelectionView.swift
//  Wordbook
//
//  Created by Masanori on 2024/08/22.
//

import SwiftUI

struct CommonTagSelectionView: View {
    @State private var tags: [TagStoreItem] = []
    @Binding var selectedTag: TagStoreItem?
    @State private var newName: String = ""
    @State private var showInputModal = false
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                Button(action: {
                    self.selectedTag = nil
                    self.dismiss()
                }) {
                    HStack {
                        Text("Tagを選択しない")
                    }
                }
                ForEach(tags) { tag in
                    Button(action: {
                        self.selectedTag = tag
                        self.dismiss()
                    }) {
                        HStack {
                            Text(tag.name)
                        }
                    }
                }
            }
            .sheet(isPresented: $showInputModal, onDismiss: {
                if (self.newName != "") {
                    let newTag = TagStoreItem(name: self.newName)
                    tags.insert(newTag, at: tags.firstIndex(where: {$0.name > newTag.name}) ?? 0)
                    MainTab.TagJSON?.inserrtTags(tags_add: [newTag])
                    self.newName = ""
                }
            }) {
                ListInputView(name: self.$newName)
            }
            Button(action: {
                self.showInputModal.toggle()
            }) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            .padding()
        }
        .task{
            tags = MainTab.TagJSON?.getAllTags() ?? []
        }
        .navigationBarTitle("Tagの選択")

    }
}


struct ListInputView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var name: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0){
            Spacer()
            Text("Tag名を入力")
            TextField("Tag", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    self.name = ""
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
                .disabled(name.count == 0)
                Spacer()
            }
        }
        .padding()
    }
}
