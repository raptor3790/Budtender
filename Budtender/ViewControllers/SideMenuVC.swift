//
//  SideMenuVC.swift
//  Budtender
//
//  Created by raptor on 20/01/2018.
//  Copyright © 2018 raptor. All rights reserved.
//

import UIKit

@objc protocol SideMenuDelegate: class {
    @objc optional func onStatus()
    @objc optional func onNews()
    @objc optional func onFAQ()
    @objc optional func onProducts()
    @objc optional func onShare()
    @objc optional func onLogout()
}

class SideMenuVC: UIViewController {
    var delegate: SideMenuDelegate?

    @IBAction func onMenuActions(_ sender: UIButton) {
        dismiss(animated: true) {
            switch sender.tag {
            case 1: // status
                self.delegate?.onStatus?()
            case 2: // news
                self.delegate?.onNews?()
            case 3: // faq
                self.delegate?.onFAQ?()
            case 4: // products
                self.delegate?.onProducts?()
            case 5: // share
                self.delegate?.onShare?()
            case 6: // logout
                self.delegate?.onLogout?()
            default:
                break
            }
        }
    }
}
