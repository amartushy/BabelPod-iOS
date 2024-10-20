//
//  LandmarkDetailsView.swift
//  TravelAI
//
//  Created by Adrian Martushev on 10/14/24.
//

import SwiftUI


struct MenuDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var imageVM: ImageViewModel
    
    var screenWidth = UIScreen.main.bounds.width
    
    var body: some View {
        
        ScrollView(.vertical, showsIndicators: false) {
            
            VStack {
                
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                VStack {
//                    CachedAsyncImageView(urlString: landmark.image)
//                        .scaledToFill()
//                        .frame( height : 240)
//                        .frame(maxWidth : screenWidth - 40)
//                        .cornerRadius(10, corners: [.topLeft, .topRight])
//                    

                }
                .background(.white)
                .cornerRadius(10)
                .padding()
                
                Spacer()
            }
        }
        .background(.regularMaterial)

    }
}

#Preview {
    MenuDetailsView()

}
