//
//  SplashScreen.swift
//  TravelAI
//
//  Created by Adrian Martushev on 9/30/24.
//

import SwiftUI

struct SplashScreen: View {
    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack { Spacer() }
            ZStack {
                Image(systemName : "globe.desk.fill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.indigo)
                    .padding()
            }
            .frame(width : 120, height : 120)
            .background(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 25)
                    .stroke(.white.opacity(0.01), lineWidth : 1)
            }
            .cornerRadius(25)
            .shadow(color : .gray.opacity(0.1), radius: 0.5, x : 0, y : 1)
            .shadow(color : .white.opacity(0.4), radius: 0.5, x : 0, y : -1)
            
            Spacer()

            ProgressView()
            
            Spacer()
            
        }
        .background {
            Color.background.edgesIgnoringSafeArea(.all)
        }
    }
}

#Preview {
    SplashScreen()
}
