//
//  TagSelectionView.swift
//  ShareToWordbook
//
//  Created by Masanori on 2024/09/01.
//

import SwiftUI
import SwiftData

struct TagSelectionView: View {
    @State var tags: [Tag] = []
    @Binding var selectedTag: Tag?
    @State private var newName: String = ""
    @State private var showInputModal = false
    @State private var context: ModelContext?
    @Environment(\.dismiss) private var dismiss
        
    func taginit() {
        Task { @MainActor in
        // SwiftDataからデータ取得
            let context = sharedModelContainer.mainContext
            let tags = (try? context.fetch(FetchDescriptor<Tag>()))?.sorted(by: { $0.name < $1.name }) ?? []
            self.context = context
            self.tags = tags
        }
    }
    
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
                    let newTag = Tag(name: self.newName)
                    context?.insert(newTag)
                    self.tags.insert(newTag, at: tags.firstIndex(where: {$0.name > newTag.name }) ?? tags.endIndex)
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
        .task {
            await taginit()
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

