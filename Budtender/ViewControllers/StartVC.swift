//
//  ViewController.swift
//  Budtender
//
//  Created by raptor on 20/01/2018.
//  Copyright © 2018 raptor. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FacebookCore
import FacebookLogin
import SwiftyJSON

class StartVC: CommonVC {
    var directMainVC: Bool = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // google login
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self

        // rating countdown
        let countdown = getInt(.ratingCount) + 1
        set(countdown, forKey: .ratingCount)

        // already logged in?
        if isLogged || directMainVC {
            performSegue(withIdentifier: "main", sender: nil)
            directMainVC = false
        } else if countdown == 5 {
            let alertVC = UIAlertController(
                title: "Rate Us",
                message: "Do you like our app?",
                preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.set(0, forKey: .ratingCount)
            }))
            alertVC.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                self.openUrl("itms-apps://itunes.apple.com/app/id1340019859")
            }))
            present(alertVC, animated: true, completion: nil)
        }

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? LoginVC {
            vc.navVC = navigationController
        }
    }

    @IBAction func onFacebookAction(_ sender: UIButton) {
        if let token = AccessToken.current {
            // already logged in
            handleFacebookLoginResult(token: token)
        } else {
            let loginManager = LoginManager()
            loginManager.logIn(readPermissions: [.publicProfile, .email, .userPhotos], viewController: self) { loginResult in
                switch loginResult {
                case .failed(let error):
                    print(error)
                case .cancelled:
                    print("User cancelled login")
                case .success(_, _, let token):
                    print("Logged in!")
                    self.handleFacebookLoginResult(token: token)
                }
            }
        }
    }

    @IBAction func onGoogleAction(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }

    @IBAction func onGuestAction(_ sender: UIButton) {
        clear()
        performSegue(withIdentifier: "main", sender: nil)
    }

    func signIn(email: String, userName: String, photo: String?, type: String) {
        var param: [String: Any] = [
            "u": userName,
            "e": email,
            "a": "cf90e169e1137c845181f580e318d4e5",
            "s": type
        ]
        if let photo = photo {
            param["i"] = photo
        }
        post(url: "/includes/register.php", param: param) { json in
            self.set(json["uid"].intValue, forKey: .userId)
            self.set(json["at"].stringValue, forKey: .authToken)

            self.performSegue(withIdentifier: "main", sender: nil)
        }

        if type == "google" {
            GIDSignIn.sharedInstance().signOut()
        }
    }

    func handleFacebookLoginResult(token: AccessToken) {
        let connection = GraphRequestConnection()
        connection.add(GraphRequest(
            graphPath: "/me",
            parameters: ["fields": "id,name,email,link"],
            accessToken: token,
            httpMethod: .GET,
            apiVersion: .defaultVersion)) { httpResponse, result in

            switch result {
            case .success(let response):
                print("Graph Request Succeeded: \(response)")
                self.facebookPhoto(token: token, param: JSON(response.dictionaryValue!))
            case .failed(let error):
                print("Graph Request Failed (/me) : \(error)")
            }
        }
        connection.start()
    }

    func facebookPhoto(token: AccessToken, param: JSON) {
        guard let userId = param["id"].string else { return }
        guard let email = param["email"].string else { return }
        guard let name = param["name"].string else { return }

        let connection = GraphRequestConnection()
        connection.add(GraphRequest(
            graphPath: "/\(userId)/picture",
            parameters: ["redirect": false, "type": "normal"],
            accessToken: token,
            httpMethod: .GET,
            apiVersion: .defaultVersion)) { httpResponse, result in

            switch result {
            case .success(let response):
                self.signIn(email: email, userName: name, photo: JSON(response.dictionaryValue!)["data"]["url"].string, type: "facebook")
            case .failed(let error):
                print("Graph Request Failed (/\(userId)/picture : \(error)")
            }
        }
        connection.start()
    }
}

// Google Sign In
extension StartVC: GIDSignInDelegate, GIDSignInUIDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("Google sign in failed: \(error)")
            self.view.makeToast("Google login failed", duration: 2, position: .center)
            return;
        }

        if let email = user.profile.email, let userName = user.profile.name {
            self.signIn(email: email, userName: userName, photo: user.profile.imageURL(withDimension: 120).absoluteString, type: "google")
        }

        print("Google sign in with user: \(user)")
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google signin disconnect")
        self.view.makeToast("Google login failed", duration: 2, position: .center)
    }
}

