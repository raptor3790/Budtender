//
//  DetailVC.swift
//  Budtender
//
//  Created by raptor on 20/01/2018.
//  Copyright © 2018 raptor. All rights reserved.
//

import UIKit

class DetailVC: CommonVC {
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var textTitle: UILabel!
    @IBOutlet weak var textBody: UILabel!
    @IBOutlet weak var btnVisit: UIButton!

    var feed: Feed!
    var feedType: FeedType!

    override func viewDidLoad() {
        super.viewDidLoad()

        // title
        switch feedType! {
        case .news: title = "Canadian Cannabis News"
        case .faq: title = "View Answer"
        case .product: title = "Product Description"
        default: break
        }
        // photo
        if let urlString = feed.imageURL, let url = URL(string: urlString) {
            imgPhoto.sd_setImage(with: url, placeholderImage: #imageLiteral(resourceName: "camera"))
        } else {
            imgPhoto.image = #imageLiteral(resourceName: "camera")
        }
        // title
        textTitle.text = feed.title
        // body
        textBody.text = feed.body
        // visit
        if let urlString = feed.clickURL, let _ = URL(string: urlString) {
            btnVisit.isEnabled = true
        } else {
            btnVisit.isEnabled = false
            btnVisit.backgroundColor = .lightGray
        }
    }

    @IBAction func onVisitAction(_ sender: UIButton) {
        let url = URL(string: feed.clickURL!)!
        UIApplication.shared.open(url)
    }
}
