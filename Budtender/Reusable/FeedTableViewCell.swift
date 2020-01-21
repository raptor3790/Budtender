//
//  FeedTableViewCell.swift
//  Budtender
//
//  Created by raptor on 20/01/2018.
//  Copyright © 2018 raptor. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell {
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var favorite: UIButton!

    var onFavorite: ((_ button: UIButton) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func onFavoriteAction(_ sender: UIButton) {
        onFavorite?(sender)
    }
}
