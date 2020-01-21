//
//  LoginVC.swift
//  Budtender
//
//  Created by raptor on 20/01/2018.
//  Copyright © 2018 raptor. All rights reserved.
//

import UIKit
import SwiftValidators
import Toast_Swift
import CryptoSwift

class LoginVC: CommonVC {
    @IBOutlet weak var email1: UITextField!
    @IBOutlet weak var password1: UITextField!
    @IBOutlet weak var email2: UITextField!
    @IBOutlet weak var password2: UITextField!
    @IBOutlet weak var confirm2: UITextField!

    weak var navVC: UINavigationController?

    @IBAction func onCloseAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func onSignInAction(_ sender: UIButton) {
        if !Validator.isEmail().apply(email1.text) {
            view.makeToast("Email address invalid", duration: 2, position: .center)
            email1.becomeFirstResponder()
        } else if !Validator.minLength(6).apply(password1.text) {
            view.makeToast("Password at least 6 characters long", duration: 2, position: .center)
            password1.becomeFirstResponder()
        } else {
            dismissKeyboard()
            signIn(email: email1.text!, password: password1.text!)
        }
    }

    @IBAction func onSignUpAction(_ sender: UIButton) {
        if !Validator.isEmail().apply(email2.text) {
            view.makeToast("Email address invalid", duration: 2, position: .center)
            email2.becomeFirstResponder()
        } else if !Validator.minLength(6).apply(password2.text) {
            view.makeToast("Password at least 6 characters long", duration: 2, position: .center)
            password2.becomeFirstResponder()
        } else if !Validator.equals(password2.text!).apply(confirm2.text) {
            view.makeToast("Password mismatch", duration: 2, position: .center)
            confirm2.becomeFirstResponder()
        } else {
            dismissKeyboard()
            signUp(email: email2.text!, password: password2.text!)
        }
    }

    func signIn(email: String, password: String) {
        let params: [String: Any] = [
            "u": email,
            "p": password.sha512(),
            "di": 1, /* 0: Android, 1: iOS */
            "dt": "",
            "imei": ""
        ]
        post(url: "/API_login.php", param: params) { json in
            self.set(json["uid"].intValue, forKey: .userId)
            self.set(json["at"].stringValue, forKey: .authToken)

            self.dismiss(animated: true, completion: {
                if let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainVC") {
                    self.navVC?.pushViewController(vc, animated: true)
                }
            })
        }
    }

    func signUp(email: String, password: String) {
        let params: [String: Any] = [
            "email": email,
            "p": password.sha512()
        ]
        post(url: "/includes/register.php", param: params) { _ in
            self.signIn(email: email, password: password)
        }
    }
}

extension LoginVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField === email1) {
            password1.becomeFirstResponder()
        } else if (textField === password1) {
            textField.resignFirstResponder()
        } else if (textField === email2) {
            password2.becomeFirstResponder()
        } else if (textField === password2) {
            confirm2.becomeFirstResponder()
        } else if(textField === confirm2) {
            textField.resignFirstResponder()
        }

        return true
    }
}
