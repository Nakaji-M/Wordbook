//
//  WordEditSheet.swift
//  Wordbook
//
//  Created by 中島正矩 on 2024/10/26.
//

import SwiftUI

// 編集画面
struct WordEditSheet: View {
    @State private var tags: [TagStoreItem] = []
    @Binding var viewModel: WordStoreItem
    @State var selectedTag: TagStoreItem?
    @State var showLoadingAlert: Bool = false //実質使用していない
    @State var alertMessage: String = "" //実質使用していない
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack{
            ScrollView{
                VStack(alignment: .leading, spacing: 8){
                    NavigationLink(destination:
                        CommonTagSelectionView(selectedTag: $selectedTag)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("完了") {
                                    dismiss()
                                }
                            }
                        }
                    )
                    {
                        HStack(spacing: 8) {
                            Label("Tag", systemImage: "tag")
                            Spacer()
                            Text(selectedTag?.name ?? "未設定")
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .opacity(0.5)
                        }
                        .padding(.vertical)
                    }

                    CommonWordEditView(viewModel: $viewModel)
                }
                .padding(.all)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .navigationBarTitle("単語の編集")
        }
        .onChange(of: selectedTag) {
            viewModel.tag = selectedTag?.id
        }
        .onAppear {
            if let id = viewModel.tag {
                selectedTag = getTagfromId(id: id)
            }
            else {
                selectedTag = nil
            }
        }
        .task{
            tags = MainTab.TagJSON?.getAllTags() ?? []
        }
    }
    
    func getTagfromId(id: UUID) -> TagStoreItem? {
        return tags.first(where: { $0.id == id })
    }
}

