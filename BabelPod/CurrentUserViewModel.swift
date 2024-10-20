
import SwiftUI
import Foundation
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage


struct UserCommunications {
    var email : String
    var isPushOn: Bool
    var pushToken: String
}

struct User: Identifiable {
    var id: String
    var profilePhoto: String
    var name: String
    var dateJoined: Date
    var authProvider: String
    var isSubscribed: Bool
    var communications: UserCommunications
    
    enum CodingKeys: String, CodingKey {
        case id = "objectID"
        case profilePhoto,
             name,
             username,
             dateJoined,
             authProvider,
             isSubscribed,
             communications
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "profilePhoto": profilePhoto,
            "name": name,
            "dateJoined": Timestamp(date: dateJoined),
            "authProvider": authProvider,
            "isSubscribed": isSubscribed,
            "communications": [
                "email": communications.email,
                "isPushOn": communications.isPushOn,
                "pushToken": communications.pushToken
            ]
        ]
    }
}

func createUserModel(from userData: [String: Any]) -> User {
    
    let communicationsDict = userData["communications"] as? [String: Any] ?? [:]
    let communications = UserCommunications(
        email: communicationsDict["email"] as? String ?? "",
        isPushOn: communicationsDict["isPushOn"] as? Bool ?? false,
        pushToken: communicationsDict["pushToken"] as? String ?? ""
    )
    
    let dateJoinedTimestamp = userData["dateJoined"] as? Timestamp
    let dateJoined = dateJoinedTimestamp?.dateValue() ?? Date()
    
    return User(
        id: userData["id"] as? String ?? "",
        profilePhoto: userData["profilePhoto"] as? String ?? "",
        name: userData["name"] as? String ?? "",
        dateJoined: dateJoined,
        authProvider: userData["authProvider"] as? String ?? "",
        isSubscribed: userData["isSubscribed"] as? Bool ?? false,
        communications: communications
    )
}

let empty_communications = UserCommunications(
    email: "",
    isPushOn: false,
    pushToken: ""
)

let empty_user = User(
    id: "",
    profilePhoto: "",
    name: "",
    dateJoined: Date(),
    authProvider: "",
    isSubscribed: false,
    communications: empty_communications
)


class CurrentUserViewModel : NSObject, ObservableObject {
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    @Published var refreshID = UUID()
    
    //Authentication
    var currentNonce: String?
    @Published var shouldDeleteAccount = false
    var appleSignInCompletionHandler: ((Bool, Error?) -> Void)?
    
    @Published var user : User = empty_user

    
    //Handles real-time authentication changes to conditionally display login/home views
    var didChange = PassthroughSubject<CurrentUserViewModel, Never>()
    
    @Published var currentUserID: String = "" {
        didSet {
            didChange.send(self)
        }
    }
    
    var handle: AuthStateDidChangeListenerHandle?
    var coreUserChangesListener: ListenerRegistration?

    func listen () {
        handle = Auth.auth().addStateDidChangeListener { [self] (auth, user) in
            if let user = user {
                
                print("User Authenticated: \(user.uid)")
                self.currentUserID = user.uid
                self.getUserInfo(userID: user.uid)

            } else {
                print("No user available, loading initial view")
                self.currentUserID = ""
            }
        }
    }
    
    //Fetch initial data once, add listeners for appropriate conditions
    func getUserInfo(userID: String) {
        let userInfo = database.collection("users").document(userID)
        
        userInfo.getDocument { documentSnapshot, error in
            guard documentSnapshot != nil else {
                print("Error fetching document: \(error!)")
                return
            }

            self.listenForCoreUserChanges(userID: self.currentUserID)
        }
    }
    
    func listenForCoreUserChanges(userID: String) {
        coreUserChangesListener = database.collection("users").document(userID).addSnapshotListener { snapshot, error in
            guard let document = snapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            
            guard let userData = document.data() else {
                print("User is authenticated but no user document exists.")
                return
            }
            
            let user = createUserModel(from: userData)
            self.user = user
        }
    }


    
    //MARK: User Updates
    
    func updateUser(data: [String: Any]) {
        
        if self.currentUserID != "" {
            let userInfo = database.collection("users").document(self.currentUserID)
            userInfo.updateData(data) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("User data successfully updated: \(data)")
                }
            }
        } else {
            print("Attempting to update non existent user with data : \(data)")
        }
    }
    
    func updateUserWithCompletion(data: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        
        let userInfo = database.collection("users").document(self.currentUserID)
        userInfo.updateData(data) { err in
            if let err = err {
                print("Error updating document: \(err)")
                completion(.failure(err))
            } else {
                print("User data successfully updated : \(data)")
                completion(.success(()))
            }
        }
    }
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        let imageData = image.jpegData(compressionQuality: 0.4)
        let storageRef = Storage.storage().reference().child("profilePhotos/\(self.currentUserID).jpg")

        storageRef.putData(imageData!, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url))
                }
            }
        }
    }
    
    func updateUserProfilePhotoURL(_ url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()

        db.collection("users").document(self.currentUserID).updateData(["profilePhoto": url.absoluteString]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Successfully updated profile photo")
                completion(.success(()))
            }
        }
    }
    
    func enablePush() {
                
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if let error = error {
                print("Failed to register with error: \(error.localizedDescription)")
            } else {
                print("Success! We authorized notifications")
                
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    
                    if self.currentUserID != "" {
                        let userRef = database.collection("users").document(self.currentUserID)
                        userRef.updateData(["communications.isPushOn": true, "communications.pushToken": self.delegate.deviceToken]) { error in
                            if let error = error {
                                print("Error updating document: \(error)")
                            } else {
                                print("Push Notifications Enabled with token \(self.user.communications.pushToken)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func disablePush() {
        if self.currentUserID != "" {
            let userRef = database.collection("users").document(self.currentUserID)
            self.user.communications.pushToken = ""
            userRef.updateData([ "communications.isPushOn": false, "communications.pushToken" :  self.delegate.deviceToken]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Disabled push notifications")
                }
            }
        }
    }
    
    
    //MARK: Termination Steps
    
    func signOut(appManager : AppManager) {
        do {
            coreUserChangesListener?.remove()
            coreUserChangesListener = nil
            
            try Auth.auth().signOut()
            print("Successfully signed out user")
            resetCurrentUserVM()
            appManager.navigationPath = [.initial]
            
        } catch {
            print("Error signing out user")
        }
    }
    
    func resetCurrentUserVM() {
        print("Resetting CurrentUserViewModel")
        refreshID = UUID()
            
        currentUserID = ""
        user = empty_user
    }
}
