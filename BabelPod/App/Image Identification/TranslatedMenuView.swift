//
//  TranslatedMenuView.swift
//  BabelPod
//
//  Created by Adrian Martushev on 10/19/24.
//

import SwiftUI

struct TranslatedMenuView: View {
    @EnvironmentObject var imageVM : ImageViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var query : String = ""
    
    var filteredMenu: [MenuItem] {
        if query.isEmpty {
            return imageVM.menuItems
        } else {
            return imageVM.menuItems.filter { menuItem in
                menuItem.itemName.lowercased().contains(query.lowercased()) ||
                menuItem.translatedItemName.lowercased().contains(query.lowercased())
            }
        }
    }
    
    var body: some View {
        
        VStack {
            ZStack {
                HStack {
                    Button {
                        dismiss()
                    } label : {
                        CircularIcon(icon: "arrow.left")
                    }
                    Spacer()
                }
                Text("Menu")
                    .font(.custom("Raleway-Bold", size: 14))
            }
            .padding(.horizontal)
            .toolbar(.hidden)

            Divider()

            
            ScrollView(.vertical, showsIndicators: false) {
                
                BabelTextField(text: $query, icon: "magnifyingglass", placeholder: "Search menu..")
                    .padding(.trailing)
                    .padding(.vertical, 20)
                
                VStack {
                    ForEach(filteredMenu, id : \.self) { menuItem in
                        HStack {
                            VStack(alignment : .leading) {
                                Text(menuItem.itemName)
                                Text(menuItem.translatedItemName)
                                    .font(.custom("Raleway", size: 16))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Spacer()
                            Text(menuItem.price)
                        }
                        .padding()
                        .font(.custom("Raleway-SemiBold", size: 16))
                        .background(.onyx)
                        .cornerRadius(10)
                        
                    }
                    Spacer()
                }
                .padding(.trailing)
            }
            .padding(.leading)
        }
        .background(Color.background)
    }
}


#Preview {
    TranslatedMenuView()
}
