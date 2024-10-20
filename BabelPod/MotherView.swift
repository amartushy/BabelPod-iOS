//
//  MotherView.swift
//  TravelAI
//
//  Created by Adrian Martushev on 9/30/24.
//

import SwiftUI

struct MotherView: View {
    @EnvironmentObject var keyboardResponder: KeyboardResponder
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var currentUserVM: CurrentUserViewModel

    var body: some View {

        ZStack {
            VStack(spacing : 0) {
                NavigationStack(path: $appManager.navigationPath) {
                    EmptyView()
                        .navigationDestination(for: NavigationState.self) { index in
                            switch index {
                            case .initial :
                                InitialView()
                                    .toolbar(.hidden)
                                
                            case .app :
                                
                                ZStack {
                                    VStack(spacing : 0) {
                                        switch appManager.tabShowing {
                                        case .Home:
                                            HomeView()
                                                .toolbar(.hidden)
                                        case .Audio :
                                            ListeningView()
                                        case .Account :
                                            AccountView()
                                                .toolbar(.hidden)
                                        }
                                        
                                        Divider()
                                        
                                        TabsLayoutView(selectedTab: $appManager.tabShowing)
                                    }
    //                                .fullScreenCover(isPresented: $appManager.showSubscribeOverlay) {
    //                                    SubscriptionView()
    //                                }
                                    
                                    VStack(spacing : 0) {
                                        Spacer()
                                        Divider()
                                        
                                        if !keyboardResponder.isKeyboardVisible {
                                            TabsLayoutView(selectedTab: $appManager.tabShowing)
                                        }
                                    }
                                }

                            }
                       }
                }
            }
            
            if appManager.showSplashScreen {
                SplashScreen()
            }
        }
        .animation(.default, value: keyboardResponder.isKeyboardVisible)
        .animation(.default, value: appManager.showSplashScreen)
        .onAppear {
            handleAppInitialization()
        }
        .onChange(of: currentUserVM.currentUserID) { _, newUserID in
            handleUserChange(for: newUserID)
        }
    }
    
    private func handleAppInitialization() {
        appManager.showSplash()
    }
    
    
    private func handleUserChange(for userID: String) {
        print("UserID changed : \(userID)")
        guard !userID.isEmpty else {
            appManager.navigationPath = [.initial]
            return
        }

        appManager.navigationPath = [.app]
    }
}



fileprivate struct TabsLayoutView: View {

    @Binding var selectedTab: Tab
    @Namespace var namespace
    
    var body: some View {
        ZStack {
   
            HStack {
                Spacer()
                TabButton(tab: .Home, selectedTab: $selectedTab, namespace: namespace)
                Spacer()
                TabButton(tab: .Audio, selectedTab: $selectedTab, namespace: namespace)
                Spacer()
                TabButton(tab: .Account, selectedTab: $selectedTab, namespace: namespace)
                Spacer()
            }
            .background(.ultraThinMaterial)
        }
    }
    
    private struct TabButton: View {
        let tab: Tab
        @Binding var selectedTab: Tab
        var namespace: Namespace.ID
        @EnvironmentObject var appManager: AppManager

        var body: some View {
            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.9, blendDuration: 0.6)) {
                    selectedTab = tab
                    appManager.navigationPath = [.app]
                }
            } label: {
                ZStack {
                    
                    VStack (spacing : 0) {
                        Image(systemName: selectedTab == tab ? "\(tab.icon).fill" : tab.icon )
                            .foregroundColor(selectedTab == tab ? .indigo : .white.opacity(0.4) )
                            .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .light, design: .rounded))
                            .scaleEffect(isSelected ? 1 : 0.9)
                            .animation(isSelected ? .spring(response: 0.5, dampingFraction: 0.3, blendDuration: 1) : .spring(), value: selectedTab)
                        
                        Text("\(String(describing: tab))")
                            .font(.custom("Manrope-Regular", size: 10))
                            .foregroundColor(selectedTab == tab ? .indigo : .white.opacity(0.4) )
                            .padding(.top, 5)
                    }
                    .frame(width : 70, height : 55)
                }
                .foregroundColor(.white)
                .frame(width : 70, height : 55)

            }
        }
        
        private var isSelected: Bool {
            selectedTab == tab
        }
    }
}


#Preview {
    MotherView()
        .environmentObject(KeyboardResponder())
        .environmentObject(AppManager())
}
