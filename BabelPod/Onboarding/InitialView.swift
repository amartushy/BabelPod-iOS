//
//  Initialview.swift
//  TravelAI
//
//  Created by Adrian Martushev on 9/30/24.
//

import SwiftUI


struct InitialView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var authVM = AuthenticationViewModel()

    @State var showTOS = false
    @State var showPP = false

    var screenWidth = UIScreen.main.bounds.width
    var body: some View {
        
        ZStack {
            
            VStack {
                Spacer()

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

                VStack(spacing : 10) {
                    Text("Welcome to")
                        .font(.custom("Raleway-Light", size: 16))

                    Text("BabelPod")
                        .font(.custom("Raleway-Bold", size: 48))
                }
                
                Spacer()

                VStack(alignment : .leading, spacing : 12) {
                    VStack(alignment : .leading) {
                        Text("Get started")
                            .font(.custom("Raleway-SemiBold", size: 24))
                        
                        Text("Create your free account to continue")
                            .font(.custom("Raleway-Regular", size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom)
                    
                    LoginOptionsView(authVM: authVM)

                }
                .padding(24)
                .background(.jetBlack)
                .cornerRadius(35)

                VStack {
                    Text("By continuing you agree to the")
                    HStack(spacing : 0) {
                        Button {
                            showTOS = true
                        } label: {
                            Text("Terms & Conditions").underline()
                        }
                        .foregroundColor(.indigo)

                        Text("and   ")
                        
                        Button {
                            showPP = true
                        } label: {
                            Text("Privacy Policy").underline()
                        }
                        .foregroundColor(.indigo)
                    }
                }
                .font(Font.custom("Avenir Next", size: 10))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .frame(width: 193, height: 40, alignment: .center)
                .padding(.bottom, 40)
                .padding(.top)
            }
            .padding()
            .background(Color.background)
            .overlay(
                Color.black.opacity(authVM.showErrorMessageModal ? 0.5 : 0)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            authVM.showErrorMessageModal = false
                        }
                    }
            )
            .edgesIgnoringSafeArea(.top)

        }
    }
}



struct LoginOptionsView : View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var currentUserVM: CurrentUserViewModel

    @State var currentNonce: String?
        
    @ObservedObject var authVM : AuthenticationViewModel
    
    var buttonHeight : CGFloat = 60
    
    var body: some View {
        VStack(spacing : 12) {
            Button {
                appManager.showSplash()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    appManager.navigationPath = [.app]
                }
                
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Continue with Email")
                        .font(.custom("Raleway-Medium", size: 16))
                }
                .padding(.horizontal)
                .foregroundStyle(.white)
                .frame(height: buttonHeight)
                .frame(maxWidth : .infinity)
                .background(.onyx)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                    .inset(by: 0.75)
                    .stroke(Color(.white.opacity(0.1)), lineWidth: 1.5)
                )
            }

            
            HStack(spacing : 12) {
                Button(action: {
                    authVM.signInWithGoogle(appManager: appManager, currentUserVM: currentUserVM)
                }, label: {
                    HStack {
                        Spacer()
                        Image("google-logo")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundStyle(.white)
                            .scaledToFill()
                            .frame(width : 20, height : 20)

                        Spacer()
                    }
                    .frame(height: buttonHeight)
                    .background(.onyx)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                        .inset(by: 0.75)
                        .stroke(Color(.white.opacity(0.1)), lineWidth: 1.5)
                    )
                })
                
                Button(action: {
                    authVM.startSignInWithAppleFlow(appManager: appManager, currentUser: currentUserVM) { result, error in
                        if let myError = error {
                            authVM.showErrorMessageModal = true
                            authVM.errorMessage = "There was an issue with Apple Sign in \(myError.localizedDescription)"
                        } else {
                            print("No error occurred")
                        }
                    }
                }, label: {
                    HStack {
                        Spacer()
                        Image("apple-logo")
                            .renderingMode(.template)
                            .resizable()
                            .foregroundColor(.white)
                            .scaledToFill()
                            .frame(width : 20, height : 20)

                        Spacer()
                    }
                    .frame(height: buttonHeight)
                    .background(.onyx)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                        .inset(by: 0.75)
                        .stroke(Color(.white.opacity(0.1)), lineWidth: 1.5)
                    )
                })
            }
        }
    }
}

#Preview {
    InitialView()
        .environmentObject(AppManager())
}
