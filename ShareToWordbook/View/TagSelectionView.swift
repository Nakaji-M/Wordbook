//
//  TagSelectionView.swift
//  ShareToWordbook
//
//  Created by Masanori on 2024/09/01.
//

import SwiftUI

struct TagSelectionView: View {
    var TagJSON: TagStoreService = TagStoreService()
    @State private var tags: [TagStoreItem] = []
    @Binding var selectedTag: TagStoreItem?
    @State private var newName: String = ""
    @State private var showInputModal = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                Button(action: {
                    self.selectedTag = nil
                    dismiss()
                }) {
                    HStack {
                        Text("Tagを選択しない")
                    }
                }
                ForEach(tags) { tag in
                    Button(action: {
                        self.selectedTag = tag
                        dismiss()
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
                    TagJSON.inserrtTags(tags_add: [newTag])
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
            tags = TagJSON.getAllTags()
        }
        .navigationBarTitle("Tagの選択")

    }
}


struct ListInputView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var name: String
    
    var body: some View {
        VStack(alignment: .leading){
            Spacer()
            Text("Tag名を入力")
            TextField("Tag", text: $name)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
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

