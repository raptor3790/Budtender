//
//  Feed.swift
//  Budtender
//
//  Created by raptor on 20/01/2018.
//  Copyright © 2018 raptor. All rights reserved.
//

import Foundation
import SwiftyJSON

enum FeedType: String {
    case status, news, product, faq
}

class Feed: NSObject {
    var id: Int!
    var title: String!
    var body: String!
    var clickURL: String!
    var imageURL: String!
    var date: String!
    var favorite: Bool!
    var watched: Bool!

    init(json: JSON) {
        super.init()

        id = json["id"].int
        title = json["title"].string
        body = json["body"].string
        clickURL = json["clickURL"].string
        imageURL = json["imageURL"].string
        date = json["date"].string
        favorite = json["isfavorite"].int ?? 0 == 1
        watched = json["iswatched"].int ?? 0 == 1
    }
}
