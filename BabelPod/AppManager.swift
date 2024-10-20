//
//  AppManager.swift
//  Constella
//
//  Created by Adrian Martushev on 7/8/24.
//

import Foundation
import UIKit
import SwiftUI
import FirebaseFirestore


enum Tab: Int, Identifiable, CaseIterable, Comparable {
    static func < (lhs: Tab, rhs: Tab) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case Home, Audio, Account
    
    internal var id: Int { rawValue }
    
    var icon: String {
        switch self {
        case .Home:
            return "house"
        case .Audio:
            return "waveform.circle"
        case .Account:
            return "person"
        }
    }
}

enum NavigationState {
    case initial
    case app
}


let database = Firestore.firestore()



class AppManager : ObservableObject {
    static let shared = AppManager()
    
    init() {}

    @Published var navigationPath: [NavigationState] = [.initial]
    @Published var tabShowing: Tab = Tab.Home
    @Published var showSplashScreen = true
    @Published var showOnboardingVideo = false
    
    func navigateBack() {
        if navigationPath.count > 1 {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        navigationPath = [.app]
    }
    
    func showSplash() {
        self.showSplashScreen = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.showSplashScreen = false
            }
        }
    }
}
