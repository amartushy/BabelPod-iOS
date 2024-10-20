//
//  AccountView.swift
//  whowins.ai
//
//  Created by Adrian Martushev on 10/17/24.
//

import SwiftUI


struct AccountView: View {
    @EnvironmentObject var appManager : AppManager
    @EnvironmentObject var currentUserVM : CurrentUserViewModel

    @State var showEmailSelectionSheet = false
    @State var showPhoneSelectionSheet = false
    @State var showLogoutAlert = false
    
    @State var isToggleOn = false
    
    
    var body: some View {
        
        VStack(alignment : .leading) {
            ScrollView(showsIndicators : false) {
                
                HStack(spacing : 16) {

                    Image("adrian-profile")
                        .resizable()
                        .scaledToFill()
                        .frame(width : 60, height : 60)
                        .cornerRadius(100)
                        .overlay {
                            RoundedRectangle(cornerRadius: 100)
                                .stroke(.white.opacity(0.5), lineWidth: 1)
                        }
                    
                    VStack(alignment : .leading, spacing : 4) {
                        Text("Hi, Adrian")
                            .font(.custom("Raleway-Bold", size: 20))
                        
                        HStack {
                            Circle()
                                .fill(.green)
                                .frame(width : 5, height : 5)
                            
                            Text("Joined October, 2024")
                                .font(.custom("Raleway", size: 14))
                        }
                    }
                    Spacer()
                }
                .padding(.vertical)
                .padding(.bottom, 20)
                
                SubscriptionSection()
                
                VStack(alignment : .leading, spacing : 0) {
                    Text("Profile")
                        .font(.custom("Raleway-Bold", size: 18))
                        .padding(.bottom, 16)
                              
                    Button {
                        showEmailSelectionSheet = true
                    } label : {
                        SettingsNavItem(icon: "envelope.fill", value: "adrian@orionsoftware.co", title: "E-mail Address")
                    }


                    Button {
                        showPhoneSelectionSheet = true
                    } label : {
                        SettingsNavItem(icon: "phone.fill", value: "+1 (123) 456-7890", title: "Phone Number")
                    }


                    SettingsNavItem(icon: "key.fill", value: "Change Password", title: "Password", showDivider: false)
                }
                
                VStack(alignment : .leading, spacing : 0) {
                    Text("Settings")
                        .font(.custom("Raleway-Bold", size: 18))
                        .padding(.bottom, 16)
                                        
                    SettingsToggleItem(icon: "iphone", value: "Public Profile", title: "Toggle on to have a public profile", isOn: .constant(false))

                    
                    SettingsToggleItem(icon: "iphone", value: "Push Notifications", title: "Notifications", isOn: $isToggleOn)
                    
                    Button(action: {
                        showLogoutAlert = true
                    }, label: {
                        SettingsNavItem(icon: "arrow.left.to.line.compact", value: "Log out", title: "Logout", showDivider: false)
                    })
                    .alert(isPresented: $showLogoutAlert, content: {
                        Alert(
                            title: Text("Log Out"),
                            message: Text("Are you sure you want to log out?"),
                            primaryButton: .destructive(Text("Log Out")) {
                                currentUserVM.signOut(appManager : appManager)
                            },
                            secondaryButton: .cancel()
                        )
                    })
                }
                .padding(.top, 40)

                Spacer()
                
            }
            .padding( .horizontal, 24)

        }
        .background(.regularMaterial)
    }
}

struct SubscriptionSection : View {

    @State var showSubscriptionSheet = false
    
    var body: some View {
        Button {
            showSubscriptionSheet = true
        } label: {
            HStack {
                Text("Upgrade to Premium")
                    .font(.custom("Raleway-SemiBold", size: 14))
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .frame(width : 30, height : 25)
                    .background(.gold)
                    .cornerRadius(5)
            }
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .frame(maxWidth : .infinity)
            .background(.indigo)
            .cornerRadius(15)
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.white.opacity(0.1), lineWidth : 1)
            }
        }
        .padding(.bottom, 30)
        .padding(.horizontal, 1)
//        .sheet(isPresented: $showSubscriptionSheet) {
//            SubscriptionView()
//        }
    }
}


struct SettingsNavItem : View {
    var icon : String
    var value : String
    var title : String
    var showDivider : Bool = true

    var body: some View {
        
        VStack(spacing : 0) {
            HStack(spacing : 15) {
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width : 30, height : 30)
                    .background(.charcoal)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                
                VStack(alignment : .leading) {
                    Text(value)
                        .font(.custom("Raleway-SemiBold", size: 14))
                    Text(title)
                        .font(.custom("Raleway", size: 12))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight : .bold))
                    .frame(width : 25, height : 25)
                    .background(.charcoal)
                    .foregroundStyle(.white)
                    .cornerRadius(5)
            }
            .foregroundStyle(.white.opacity(0.9))
            
            if showDivider {
                Divider().overlay(.charcoal)
                    .padding(.vertical, 16)
            }
        }

    }
}


struct SettingsToggleItem : View {
    var icon : String
    var value : String
    var title : String
    @Binding var isOn : Bool
    
    var body: some View {
        VStack(spacing : 0) {
            HStack(spacing : 15) {
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .frame(width : 30, height : 30)
                    .background(.charcoal)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                
                VStack(alignment : .leading) {
                    Text(value)
                        .font(.custom("Raleway-SemiBold", size: 14))
                    Text(title)
                        .font(.custom("Raleway", size: 12))
                }
                
                Spacer()
                
                SettingsToggle(isOn : $isOn)
            }
            .foregroundStyle(.white.opacity(0.9))
            
            Divider().overlay(.charcoal)
                .padding(.vertical, 16)
        }

    }
}


struct SettingsToggle : View {
    @Binding var isOn : Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill((isOn ? Color(.indigo) : Color(.onyx))
                .shadow(.inner(color: .white.opacity(0.8), radius: 1, x: 0, y: -1))
                .shadow(.inner(color: .black.opacity(0.3), radius: 2, x: 0, y: 2))
            )
            .frame(width: 50, height: 26)
            .overlay(
                RoundedRectangle(cornerRadius: 100 )
                    .foregroundColor(isOn ? .white : .indigo)
                    .frame(width : 20, height : 20)
                    .offset(x: isOn ? 12: -12, y: 0)
            )
            .onTapGesture {
                generateHapticFeedback()
                withAnimation {
                    isOn.toggle()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}


#Preview {
    AccountView()
        .environmentObject(AppManager())
}
