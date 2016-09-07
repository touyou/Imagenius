//
//  TweetStruct.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/06/13.
//  Copyright © 2016年 touyou. All rights reserved.
//

// ツイートを構造体で管理する

import Foundation
import SwifteriOS

struct Tweet {
    var screenName: String?
    var screenNameNoat: String?
    var userName: String?
    var userImage: NSURL?
    var userId: String?
    var userBackgroundImage: NSURL?

    var text: String?
    var createdAt: String?
    var tweetImages: [NSURL]?
    var entitiesType: String?
    var extendedEntities: [JSONValue]?

    var favorited: Bool?
    var retweeted: Bool?
    var favoriteCount: Int?
    var retweetCount: Int?

    var idStr: String?
    var userMentions: [JSONValue]?

    var isMyself: Bool = false
    var isRetweet: Bool = false

    init() {
    }

    init(tweet: JSONValue) {
        self.init(tweet: tweet, myself: "")
    }

    init(tweet: JSONValue, myself: String) {
        if let retweet = tweet["retweeted_status"].object {
            isRetweet = true
            setTweet(retweet)
        } else {
            setTweet(tweet.object!)
        }
        judgeAccount(myself)
    }

    internal mutating func setTweet(tweet: Dictionary<String, JSONValue>) {
        let user = tweet["user"]!

        // ユーザー情報
        screenNameNoat = user["screen_name"].string
        screenName = "@\(screenNameNoat ?? "")"
        userName = user["name"].string
        userImage = NSURL(string: user["profile_image_url_https"].string!)
        userId = user["id_str"].string
        userBackgroundImage = NSURL(string: user["profile_background_image_url"].string ?? "")

        // ツイート情報
        text = tweet["text"]?.string
        createdAt = NSDate().offsetFrom(dateTimeFromTwitterDate(tweet["created_at"]!.string!))
        favorited = tweet["favorited"]?.bool
        favoriteCount = tweet["favorite_count"]?.integer
        retweeted = tweet["retweeted"]?.bool
        retweetCount = tweet["retweet_count"]?.integer
        idStr = tweet["id_str"]?.string
        userMentions = tweet["entities"]!["user_mentions"].array

        // 添付ファイル情報
        guard let tweetMedia = tweet["extended_entities"] else {
            return
        }
        tweetImages = []
        for path in tweetMedia["media"].array ?? [] {
            tweetImages?.append(NSURL(string: path["media_url"].string!)!)
        }
        entitiesType = tweetMedia["media"][0]["type"].string
        extendedEntities = tweetMedia["media"].array
    }

    internal mutating func judgeAccount(myself: String) {
        if let screen = screenName {
            if screen == "@\(myself)" {
                isMyself = true
            }
        }
    }
}
