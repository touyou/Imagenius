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
/*
 [
 {
 "coordinates": null,
 "truncated": false,
 "created_at": "Tue Aug 28 21:16:23 +0000 2012",
 "favorited": false,
 "id_str": "240558470661799936",
 "in_reply_to_user_id_str": null,
 "entities": {
 "urls": [
 {
 "expanded_url": "http://blogs.ischool.berkeley.edu/i290-abdt-s12/",
 "url": "http://t.co/bfj7zkDJ",
 "indices": [
 79,
 99
 ],
 "display_url": "blogs.ischool.berkeley.edu/i290-abdt-s12/"
 }
 ],
 "hashtags": [
 
 ],
 "user_mentions": [
 {
 "name": "Cal",
 "id_str": "17445752",
 "id": 17445752,
 "indices": [
 60,
 64
 ],
 "screen_name": "Cal"
 },
 {
 "name": "Othman Laraki",
 "id_str": "20495814",
 "id": 20495814,
 "indices": [
 70,
 77
 ],
 "screen_name": "othman"
 }
 ]
 },
 "text": "just another test",
 "contributors": null,
 "id": 240558470661799936,
 "retweet_count": 0,
 "in_reply_to_status_id_str": null,
 "geo": null,
 "retweeted": false,
 "in_reply_to_user_id": null,
 "place": null,
 "source": "OAuth Dancer Reborn",
 
 "user": {
 "name": "OAuth Dancer",
 "profile_sidebar_fill_color": "DDEEF6",
 "profile_background_tile": true,
 "profile_sidebar_border_color": "C0DEED",
 "profile_image_url": "http://a0.twimg.com/profile_images/730275945/oauth-dancer_normal.jpg",
 "created_at": "Wed Mar 03 19:37:35 +0000 2010",
 "location": "San Francisco, CA",
 "follow_request_sent": false,
 "id_str": "119476949",
 "is_translator": false,
 "profile_link_color": "0084B4",
 
 "entities": {
 
 "url": {
 "urls": [
 {
 "expanded_url": null,
 "url": "http://bit.ly/oauth-dancer",
 "indices": [
 0,
 26
 ],
 "display_url": null
 }
 ]
 },
 
 "description": null
 },
 
 "default_profile": false,
 "url": "http://bit.ly/oauth-dancer",
 "contributors_enabled": false,
 "favourites_count": 7,
 "utc_offset": null,
 "profile_image_url_https": "https://si0.twimg.com/profile_images/730275945/oauth-dancer_normal.jpg",
 "id": 119476949,
 "listed_count": 1,
 "profile_use_background_image": true,
 "profile_text_color": "333333",
 "followers_count": 28,
 "lang": "en",
 "protected": false,
 "geo_enabled": true,
 "notifications": false,
 "description": "",
 "profile_background_color": "C0DEED",
 "verified": false,
 "time_zone": null,
 "profile_background_image_url_https": "https://si0.twimg.com/profile_background_images/80151733/oauth-dance.png",
 "statuses_count": 166,
 "profile_background_image_url": "http://a0.twimg.com/profile_background_images/80151733/oauth-dance.png",
 "default_profile_image": false,
 "friends_count": 14,
 "following": false,
 "show_all_inline_media": false,
 "screen_name": "oauth_dancer"
 },
 
 "in_reply_to_screen_name": null,
 "in_reply_to_status_id": null
 }
 */

struct Tweet {
    var screenName: String?
    var screenNameNoat: String?
    var userName: String?
    var userImage: URL?
    var userId: String?
    var userBackgroundImage: URL?

    var text: String?
    var createdAt: String?
    var tweetImages: [URL]?
    var entitiesType: String?
    var extendedEntities: [JSON]?

    var favorited: Bool?
    var retweeted: Bool?
    var favoriteCount: Int?
    var retweetCount: Int?
    var retweetUserImage: URL?

    var idStr: String?
    var userMentions: [JSON]?
    var urlStr: String?

    var isMyself: Bool = false
    var isRetweet: Bool = false

    init() {
    }

    init(tweet: JSON) {
        self.init(tweet: tweet, myself: "")
    }

    init(tweet: JSON, myself: String) {
        if let retweet = tweet["retweeted_status"].object {
            isRetweet = true
            let tw = tweet.object
            let user = tw?["user"]
            retweetUserImage = URL(string: (user?["profile_image_url_https"].string)!)
            setTweet(retweet)
        } else {
            setTweet(tweet.object!)
        }
        judgeAccount(myself)
    }

    internal mutating func setTweet(_ tweet: [String: JSON]) {
        let user = tweet["user"]!

        // ユーザー情報
        screenNameNoat = user["screen_name"].string
        screenName = "@\(screenNameNoat ?? "")"
        userName = user["name"].string
        userImage = URL(string: user["profile_image_url_https"].string!)
        userId = user["id_str"].string
        userBackgroundImage = URL(string: user["profile_background_image_url"].string ?? "")

        // ツイート情報
        text = tweet["text"]?.string
        createdAt = Date().offsetFrom(dateTimeFromTwitterDate(tweet["created_at"]!.string!))
        favorited = tweet["favorited"]?.bool
        favoriteCount = tweet["favorite_count"]?.integer
        retweeted = tweet["retweeted"]?.bool
        retweetCount = tweet["retweet_count"]?.integer
        idStr = tweet["id_str"]?.string
        userMentions = tweet["entities"]!["user_mentions"].array
        urlStr = "https://twitter.com/\(screenNameNoat!)/status/\(idStr!)"
        
        // 添付ファイル情報
        guard let tweetMedia = tweet["extended_entities"] else {
            return
        }
        tweetImages = []
        for path in tweetMedia["media"].array ?? [] {
            tweetImages?.append(URL(string: path["media_url"].string!)!)
        }
        entitiesType = tweetMedia["media"][0]["type"].string
        extendedEntities = tweetMedia["media"].array
    }

    internal mutating func judgeAccount(_ myself: String) {
        if let screen = screenName {
            if screen == "@\(myself)" {
                isMyself = true
            }
        }
    }
}
