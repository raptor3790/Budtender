//
//  CommonVC.swift
//  Budtender
//
//  Created by raptor on 20/01/2018.
//  Copyright © 2018 raptor. All rights reserved.
//

import UIKit
import Networking
import SwiftyJSON
import GoogleMobileAds

enum StoreKey: String {
    case userId, authToken, deviceToken, refreshDeviceToken, ratingCount
}

class CommonVC: UIViewController {
    let net: Networking = Networking(baseURL: "http://budtender.darkeconsulting.ca")
    let token_expired = "Unauthorized";

    @IBOutlet weak var adView: GADBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // keyboard
        hideKeyboardWhenTappedAround()

        // AdMob
        if let ad = adView {
            ad.adUnitID = "ca-app-pub-7651655738979324/7239201165"
            ad.rootViewController = self
            ad.load(GADRequest())
        }
    }

    var isLogged: Bool {
        if getInt(.userId) > 0, let _ = getString(.authToken) {
            return true
        }
        return false
    }
    
    func openUrl(_ urlString:String) {
        guard let url = URL(string: urlString) else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}

// storage
extension CommonVC {
    func getString(_ key: StoreKey) -> String? {
        return UserDefaults.standard.string(forKey: key.rawValue)
    }

    func getInt(_ key: StoreKey) -> Int {
        return UserDefaults.standard.integer(forKey: key.rawValue)
    }
    
    func getBool(_ key: StoreKey) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }

    func set(_ val: Any, forKey: StoreKey) {
        UserDefaults.standard.set(val, forKey: forKey.rawValue)
    }

    func clear(forKey: StoreKey) {
        UserDefaults.standard.removeObject(forKey: forKey.rawValue)
    }

    func clear() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
}

// sever api
extension CommonVC {
    func handleResponse(result: JSONResult, completion: ((_ res: JSON) -> Void)?) {
        switch result {
        case .success(let res):
            let json = JSON(res.dictionaryBody)
            if json["status"].int == 1 {
                completion?(JSON(json["data"]))
            } else if let message = json["data"].string {
                if message == token_expired {
                    clear()
                    navigationController?.popToRootViewController(animated: true)
                } else {
                    self.view.makeToast(message, duration: 2, position: .center)
                }
            } else {
                self.view.makeToast("Something went wrong, try again", duration: 2, position: .center)
            }

        case .failure(let res):
            self.view.makeToast("Failed with status code: \(res.statusCode)", duration: 2, position: .center)
            break
        }
    }

    func post(url: String, param: [String: Any]? = nil, indicator: Bool = true, completion: ((_ res: JSON) -> Void)? = nil) {
        if indicator {
            view.makeToastActivity(.center)
            view.isUserInteractionEnabled = false
        }

        print("POST: \(url)")
        net.post(url, parameterType: .formURLEncoded, parameters: param) { result in
            if indicator {
                self.view.hideToastActivity()
                self.view.isUserInteractionEnabled = true
            }
            self.handleResponse(result: result, completion: completion)
        }
    }

    func get(url: String, param: [String: Any]? = nil, indicator: Bool = true, completion: ((_ res: JSON) -> Void)? = nil) {
        if indicator {
            view.makeToastActivity(.center)
            view.isUserInteractionEnabled = false
        }

        print("GET: \(url)")
        net.get(url, parameters: param) { result in
            if indicator {
                self.view.hideToastActivity()
                self.view.isUserInteractionEnabled = true
            }
            self.handleResponse(result: result, completion: completion)
        }
    }

}
