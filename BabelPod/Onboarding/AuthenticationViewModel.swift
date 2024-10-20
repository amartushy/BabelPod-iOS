//
//  AuthenticationViewModel.swift
//  Lifestages Align
//
//  Created by Adrian Martushev on 7/26/24.
//


import Foundation
import FirebaseAuth
import Firebase
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI
import AuthenticationServices
import CryptoKit



class AuthenticationViewModel : NSObject, ObservableObject {
    @Published var currentUserVM : CurrentUserViewModel?
    @Published var appManager : AppManager?

    @Published var currentNonce: String?
    var appleSignInCompletionHandler: ((Bool, Error?) -> Void)?

    
    @Published var email : String = ""
    @Published var password : String = ""
    @Published var confirmPassword : String = ""

    @Published var showErrorMessageModal = false
    @Published var errorTitle = "Something went wrong"
    @Published var errorMessage = "There seems to be an issue. Please try again or contact support if the problem continues"
    
    func formatErrorMessage(errorDescription : String) {
        switch errorDescription {
        case "The password is invalid or the user does not have a password." :
            errorTitle = "Invalid Password"
            errorMessage = "Either your password or email is incorrect, please try again."
            
        case "The email address is badly formatted." :
            errorTitle = "Invalid Email"
            errorMessage = "There's an issue with your email. Please ensure it's formatted correctly"
            
        case "There is no user record corresponding to this identifier. The user may have been deleted." :
            errorTitle = "No Account Found"
            errorMessage = "There's no account matching that information. Please check your email and try again"
            
        default :
            errorTitle = "Something went wrong"
            errorMessage = "\(errorDescription)"
        }
    }
    
    func sendPasswordReset(completion: @escaping (Bool) -> Void) {
        guard !email.isEmpty else {
            formatErrorMessage(errorDescription: "Please enter your account email")
            self.showErrorMessageModal = true
            completion(false)
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.formatErrorMessage(errorDescription: "Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.formatErrorMessage(errorDescription: error.localizedDescription)
                self.showErrorMessageModal = true
                return
            }
            print("Successfully logged in as \(authResult?.user.email ?? "")")
        }
    }
        
    func createUserWithEmail(appManager : AppManager) {
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error creating auth user: \(error.localizedDescription)")
                self.formatErrorMessage(errorDescription: error.localizedDescription)
                self.showErrorMessageModal = true
            } else if let authResult = authResult {
                                
                // Create a new user
                var newUser = empty_user
                newUser.id = authResult.user.uid
                newUser.communications.email = self.email
                newUser.authProvider = "email"
                newUser.dateJoined = Date()
                
                // Convert user to dictionary
                let data = newUser.toDictionary()
                print("Creating new user with data : \(data)")
                
                // Add user to Firestore
                database.collection("users").document(authResult.user.uid).setData(data) { error in
                    if let error = error {
                        self.formatErrorMessage(errorDescription: error.localizedDescription)
                        self.showErrorMessageModal = true
                        print("Error writing user to Firestore: \(error.localizedDescription)")
                    } else {
                        print("User successfully written to Firestore")
                        appManager.navigationPath = [.app]

                    }
                }
            }
        }
    }
    
    func authenticateAndCreateUser( appManager : AppManager, credential : AuthCredential, currentUser : User, authProvider : String) {
        // Sign in with Firebase
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                self.showErrorMessageModal = true
                self.errorMessage = error.localizedDescription
                return
            }
            
            
            if let user = authResult?.user {
                // Successfully authenticated with Firebase. Now fetch or create user profile.
                let usersRef = Firestore.firestore().collection("users").document(user.uid)
                
                usersRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        print("User already exists in Firestore.")
                        appManager.navigationPath = [.app]

                    } else {
                        // Create a new user document in Firestore
                        var newUser = empty_user
                        newUser.id = user.uid
                        newUser.communications.email = currentUser.communications.email
                        newUser.name = currentUser.name
                        newUser.profilePhoto = currentUser.profilePhoto
                        newUser.authProvider = authProvider
                        newUser.dateJoined = Date()
                        
                        // Convert user to dictionary
                        let data = newUser.toDictionary()
                        print("Creating new user with data : \(data)")
                        
                        usersRef.setData(data) { error in
                            if let error = error {
                                self.showErrorMessageModal = true
                                self.errorMessage = "Failed to create user document: \(error.localizedDescription)"
                            } else {
                                print("User document successfully created in Firestore.")
                                appManager.navigationPath = [.app]
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getRootViewController() -> UIViewController? {
        return UIApplication.shared.windows.first?.rootViewController
    }
    
    func signInWithGoogle(appManager : AppManager, currentUserVM : CurrentUserViewModel) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        if let presentingViewController = getRootViewController() {
            
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [ self] result, error in
                if let error = error {
                    self.showErrorMessageModal = true
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString
                else {
                    return
                }

                currentUserVM.user.communications.email = user.profile?.email ?? ""
                let fullName = user.profile?.name ?? ""
                let profilePhotoUrl = user.profile?.imageURL(withDimension: 400)?.absoluteString ?? ""

                // Assign email, first name, and last name
                currentUserVM.user.communications.email = email
                currentUserVM.user.name = fullName
                currentUserVM.user.profilePhoto = profilePhotoUrl

                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

                authenticateAndCreateUser(appManager : appManager, credential: credential, currentUser: currentUserVM.user, authProvider: "google")
            }
        }
    }
    
    
    func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }

      return String(nonce)
    }
    
    @available(iOS 13, *)
    func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }
    
    
    func startSignInWithAppleFlow(appManager : AppManager, currentUser : CurrentUserViewModel, completion: @escaping (Bool, Error?) -> Void) {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()

        self.appleSignInCompletionHandler = completion
        self.currentUserVM = currentUser
        self.appManager = appManager
    }
}


@available(iOS 13.0, *)
extension AuthenticationViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the window of the current SwiftUI view
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                self.appleSignInCompletionHandler?(false, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"]))
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                self.appleSignInCompletionHandler?(false, NSError(domain: "AuthError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string"]))
                return
            }
            // Initialize a Firebase credential, including the user's full name.
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                              rawNonce: nonce,
                                                              fullName: appleIDCredential.fullName)
            
            // Update currentUser with the full name from Apple ID
            currentUserVM?.user.name = appleIDCredential.fullName?.givenName ?? ""
            currentUserVM?.user.communications.email = appleIDCredential.email ?? ""
            
            if let user = currentUserVM?.user, let appManager = self.appManager {
                authenticateAndCreateUser(appManager : appManager, credential: credential, currentUser: user, authProvider: "apple")
            } else {
                self.appleSignInCompletionHandler?(false, ("No user available for Apple Sign in" as? Error))
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error)")
        self.appleSignInCompletionHandler?(false, error)
    }

}




enum AccountDeletionResult {
    case success
    case failure(String)
    case requiresReauthentication
}


extension AuthenticationViewModel {
    func deleteUserAccount(authProvider : String, completion: @escaping (AccountDeletionResult) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure("User not signed in"))
            return
        }
        
        user.delete { [weak self] error in
            guard let self = self else { return }

            if let error = error as NSError?, error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                self.reauthenticateUser(authProvider: authProvider, completion: completion)
            } else if let error = error {
                print("Error deleting account: \(error.localizedDescription)")
                self.formatErrorMessage(errorDescription: error.localizedDescription)
                completion(.failure(error.localizedDescription))
            } else {
                print("Account deleted successfully")
                completion(.success)
            }
        }
    }
    
    private func reauthenticateUser(authProvider: String, completion: @escaping (AccountDeletionResult) -> Void) {
        switch authProvider {
        case "google":
            reauthenticateWithGoogle(completion: completion)
        case "apple":
            reauthenticateWithApple(completion: completion)
        case "email":
            completion(.requiresReauthentication)
        default:
            completion(.failure("Unknown authentication provider"))
        }
    }
    
    func loginWithEmailAndDeleteAccount(email: String, password: String, completion: @escaping (AccountDeletionResult) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.formatErrorMessage(errorDescription: error.localizedDescription)
                self.showErrorMessageModal = true
                completion(.failure("Failed to sign in: \(error.localizedDescription)"))
                return
            }

            guard let user = authResult?.user else {
                completion(.failure("Failed to authenticate the user."))
                return
            }

            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            self.reauthenticateAndDeleteUser(with: credential) { result in
                switch result {
                case .success:
                    print("Successfully deleted account")
                    completion(.success)
                case .failure(let string):
                    self.formatErrorMessage(errorDescription: "Failed to delete account: \(string)")
                    self.showErrorMessageModal = true
                    completion(.failure("Failed to delete account: \(string)"))
                case .requiresReauthentication:
                    self.formatErrorMessage(errorDescription: "Failed to delete account due to reauthentication requirement.")
                    self.showErrorMessageModal = true
                    completion(.requiresReauthentication)
                }
            }
        }
    }
    
    
    func reauthenticateWithGoogle(completion: @escaping (AccountDeletionResult) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        if let presentingViewController = getRootViewController() {
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
                guard let self = self else { return }

                if let error = error {
                    self.showErrorMessageModal = true
                    self.errorMessage = error.localizedDescription
                    completion(.failure("Re-authentication failed: \(error.localizedDescription)"))

                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    completion(.failure("Failed to retrieve authentication token during re-authentication."))

                    return
                }
                
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                self.reauthenticateAndDeleteUser(with: credential, completion: completion)
            }
        }
    }
    
    func reauthenticateWithApple(completion: @escaping (AccountDeletionResult) -> Void) {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()

        // Reuse the same completion handler to handle the result of the reauthentication
        self.appleSignInCompletionHandler = { success, error in
            if success {
                // Once successfully reauthenticated, proceed with account deletion
                self.deleteUserAccount(authProvider: "apple", completion: completion)
            } else if let error = error {
                completion(.failure("Re-authentication failed: \(error.localizedDescription)"))
            } else {
                completion(.failure("Re-authentication failed"))
            }
        }
    }

        
    func reauthenticateAndDeleteUser(with credential: AuthCredential, completion: @escaping (AccountDeletionResult) -> Void) {
        guard let user = Auth.auth().currentUser else { return }

        user.reauthenticate(with: credential) { [weak self] _, error in
            guard let self = self else { return }

            if let error = error {
                // Handle reauthentication error
                print("Error reauthenticating: \(error.localizedDescription)")
                self.formatErrorMessage(errorDescription: error.localizedDescription)
                completion(.failure("Reauthentication failed: \(error.localizedDescription)"))
            } else {
                // Reauthentication successful, try deleting again
                print("Reauthentication successful.")
                self.deleteUserAccount(authProvider: "none", completion: completion)
            }
        }
    }
}
