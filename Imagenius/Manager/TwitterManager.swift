//
//  TwitterUtil.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/22.
//  Copyright © 2016年 touyou. All rights reserved.
//

import Foundation
import UIKit
import Accounts
import SwifteriOS
import TwitterKit

final class TwitterManager {
    
    static let shared = TwitterManager()
    
    private let twitter = Twitter.sharedInstance()
    private let consumerKey = "Rh3x5hYBZtJGzfGGeeBoAXI98"
    private let consumerSecret = "AVObRmfovlMT5eymWQAoKTh8EnyweShSp5dQuHJwf2dAVcDyJy"
    private let saveData = UserDefaults.standard
    private let decoder = JSONDecoder()
    
    var currentSession: TWTRSession?
    
    init() {
        
        Twitter.sharedInstance().start(withConsumerKey: consumerKey, consumerSecret: consumerSecret)
        
        if let userID = saveData.object(forKey: Settings.Saveword.account) as? String {
            
            currentSession = twitter.sessionStore.session(forUserID: userID) as? TWTRSession
        }
        
        // Date Formatter for Twitter
        let dateFormatter = DateFormatter()
        let locale = Locale(identifier: "en_US")
        dateFormatter.locale = locale
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    func loginTwitter(_ success: (()->())? = nil) {
        
        twitter.logIn { session, error in
            
            if let newUser = session {
                
                Twitter.sharedInstance().sessionStore.save(newUser, completion: { session, error in success?()})
                self.currentSession = newUser
                UserDefaults.standard.set(newUser.userID, forKey: Settings.Saveword.account)
            } else {
                
                print(error?.localizedDescription ?? "")
            }
        }
    }
    
    func switchAccount(_ success: (()->())? = nil) {
        
        let accounts = twitter.sessionStore.existingUserSessions() as! [TWTRSession]
        var alertController = UIAlertController(title: "アカウント選択", message: "使用するTwitterアカウントを選択してください", preferredStyle: .actionSheet)
        
        for account in accounts {
            
            alertController = alertController.addAction(title: account.userName, style: .default, handler: { _ in
            
                self.currentSession = Twitter.sharedInstance().sessionStore.session(forUserID: account.userID) as? TWTRSession
                UserDefaults.standard.set(account.userID, forKey: Settings.Saveword.account)
                success?()
            })
        }
        
        alertController.addAction(title: "新しいアカウントでログインする", style: .default, handler: { _ in
            
            self.loginTwitter(success)
        }).addAction(title: "cancel", style: .cancel).show()
    }
    
    func loadHomeTimelineTweet(count: Int, maxID: String? = nil, success: @escaping (([Tweet])->Void), failure: ((Error?)->Void)? = nil) {
        
        guard let userID = currentSession?.userID else {
            
            failure?(nil)
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/statuses/home_timeline.json"
        var params = [AnyHashable: Any]()
        params["count"] = String(count)
        _ = maxID.flatMap { params["max_id"] = $0 }
        var error: NSError?
        let request = client.urlRequest(withMethod: "GET", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")

        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            do {
                
                let tweets = try self.decoder.decode([Tweet].self, from: data!)
                success(tweets)
            } catch let error {
                
                print(error)
            }
        }
    }
    
    func loadMentionsTimelineTweet(count: Int, maxID: String? = nil, success: @escaping (([Tweet])->Void), failure: ((Error?)->Void)? = nil) {
        
        guard let userID = currentSession?.userID else {
            
            failure?(nil)
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/statuses/mentions_timeline.json"
        var params = [AnyHashable: Any]()
        params["count"] = String(count)
        _ = maxID.flatMap { params["max_id"] = $0 }
        var error: NSError?
        let request = client.urlRequest(withMethod: "GET", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")
        
        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            do {
                
                let tweets = try self.decoder.decode([Tweet].self, from: data!)
                success(tweets)
            } catch let error {
                
                print(error)
            }
        }
    }
    
    func loadListTweet(for id: String, count: Int, maxID: String? = nil, success: @escaping (([Tweet])->Void), failure: ((Error?)->Void)? = nil) {
        
        guard let userID = currentSession?.userID else {
            
            failure?(nil)
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/lists/statuses.json"
        var params = [AnyHashable: Any]()
        params["count"] = String(count)
        params["list_id"] = id
        params["include_rts"] = "1"
        _ = maxID.flatMap { params["max_id"] = $0 }
        var error: NSError?
        let request = client.urlRequest(withMethod: "GET", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")
        
        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            do {
                
                let tweets = try self.decoder.decode([Tweet].self, from: data!)
                success(tweets)
            } catch let error {
                
                print(error)
            }
        }
    }
    
    func getTweet(for id: String, success: @escaping ((Tweet)->Void), failure: ((Error?)->Void)? = nil) {
        
        guard let userID = currentSession?.userID else {
            
            failure?(nil)
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/statuses/show.json"
        var params = [AnyHashable: Any]()
        params["id"] = id

        var error: NSError?
        let request = client.urlRequest(withMethod: "GET", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")
        
        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            do {
                
                let tweet = try self.decoder.decode(Tweet.self, from: data!)
                success(tweet)
            } catch let error {
                
                print(error)
            }
        }
    }
    
    func getTimeline(for id: String, count: Int, maxID: String? = nil, success: @escaping (([Tweet])->Void), failure: ((Error?)->Void)? = nil) {
        
        guard let userID = currentSession?.userID else {
            
            failure?(nil)
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/statuses/user_timeline.json"
        var params = [AnyHashable: Any]()
        params["count"] = String(count)
        params["user_id"] = id
        _ = maxID.flatMap { params["max_id"] = $0 }
        var error: NSError?
        let request = client.urlRequest(withMethod: "GET", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")
        
        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            do {
                
                let tweets = try self.decoder.decode([Tweet].self, from: data!)
                success(tweets)
            } catch let error {
                
                print(error)
            }
        }
    }
    
    func favoriteTweet(for id: String, success: @escaping (()->())) {
        
        guard let userID = currentSession?.userID else {
            
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/favorites/create.json"
        var params = [AnyHashable: Any]()
        params["id"] = id

        var error: NSError?
        let request = client.urlRequest(withMethod: "POST", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")
        
        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            success()
        }
    }
    
    func unfavoriteTweet(for id: String, success: @escaping (()->())) {
        
        guard let userID = currentSession?.userID else {
            
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/favorites/destroy.json"
        var params = [AnyHashable: Any]()
        params["id"] = id
        
        var error: NSError?
        let request = client.urlRequest(withMethod: "POST", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")
        
        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            success()
        }
    }
    
    func retweetTweet(for id: String, success: @escaping (()->())) {
        
        guard let userID = currentSession?.userID else {
            
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/statuses/retweet/\(id).json"
        let params = [AnyHashable: Any]()
        
        var error: NSError?
        let request = client.urlRequest(withMethod: "POST", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")
        
        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            success()
        }
    }
    
    func unretweetTweet(for id: String, success: @escaping (()->())) {
        
        guard let userID = currentSession?.userID else {
            
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/statuses/unretweet/\(id).json"
        let params = [AnyHashable: Any]()
        
        var error: NSError?
        let request = client.urlRequest(withMethod: "POST", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")
        
        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            success()
        }
    }
    
    func destroyTweet(for id: String, success: @escaping (()->()), failure: ((Error?)->Void)? = nil) {
        
        guard let userID = currentSession?.userID else {
            
            failure?(nil)
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/statuses/destroy/\(id).json"
        let params = [AnyHashable: Any]()
        
        var error: NSError?
        let request = client.urlRequest(withMethod: "POST", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")
        
        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            success()
        }
    }
    
    func blockUser(for name: String, success: @escaping (()->()), failure: ((Error?)->Void)? = nil) {
        
        guard let userID = currentSession?.userID else {
            
            failure?(nil)
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/blocks/create.json"
        var params = [AnyHashable: Any]()
        params["screen_name"] = name
        
        var error: NSError?
        let request = client.urlRequest(withMethod: "POST", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")
        
        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            success()
        }
    }
    
    func reportUser(for name: String, success: @escaping (()->()), failure: ((Error?)->Void)? = nil) {
        
        guard let userID = currentSession?.userID else {
            
            failure?(nil)
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/users/report_spam.json"
        var params = [AnyHashable: Any]()
        params["screen_name"] = name
        
        var error: NSError?
        let request = client.urlRequest(withMethod: "POST", url: endpoint, parameters: params, error: &error)
        print(error?.localizedDescription ?? "")
        
        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            success()
        }
    }
    // TODO: DecodableなTweetのクラスができたらそれを読み込む関数をいっぱい量産する
}

// TODO: DecodableなTweetのクラスかなにかをつくる
struct Entities: Decodable {
    
    struct TweetUrl: Decodable {
        
        let expandedUrl: URL
        let url: URL
        let indices: [Int]
        let displayUrl: String
        
        private enum CodingKeys: String, CodingKey {
            
            case expandedUrl = "expanded_url"
            case url
            case indices
            case displayUrl = "display_url"
        }
    }
    
    struct Hashtag: Decodable {
    }
    
    struct Mention: Decodable {
        
        let idStr: String
        let id: UInt64
        let indices: [Int]
        let screenName: String
        
        private enum CodingKeys: String, CodingKey {
            
            case idStr = "id_str"
            case id
            case indices
            case screenName = "screen_name"
        }
    }
    
    let urls: [TweetUrl]
    let hashtags: [Hashtag]
    let mentions: [Mention]
    
    private enum CodingKeys: String, CodingKey {
        
        case urls
        case hashtags
        case mentions = "user_mentions"
    }
}

struct UserEntities: Decodable {}

struct User: Decodable {
    
    let contributorsEnabled: Bool
    let createdAt: Date
    let defaultProfile: Bool
    let defaultProfileImage: Bool
    let description: String
    let entities: UserEntities
    let favouritesCount: Int
    let followRequestSent: Bool
    let followersCount: Int
    let following: Bool
    let friendsCount: Int
    let geoEnabled: Bool
    let id: UInt64
    let idStr: String
    let isTranslator: Bool
    let lang: String
    let listedCount: Int
    let location: String
    let name: String
    let notifications: Bool
    let profileBackgroundColor: String
    let profileBackgroundImageUrl: URL
    let profileBackgroundTile: Bool
    let profileImageUrl: URL
    let profileLinkColor: String
    let profileSidebarBorderColor: String
    let profileSidebarFillColor: String
    let profileTextColor: String
    let profileUseBackgroundImage: Bool
    let protected: Bool
    let screenName: String
    let statusesCount: Int
    let url: URL?
    let verified: Bool
    

    private enum CodingKeys: String, CodingKey {
        
        case contributorsEnabled = "contributors_enabled"
        case createdAt = "created_at"
        case defaultProfile = "default_profile"
        case defaultProfileImage = "default_profile_image"
        case description
        case entities
        case favouritesCount = "favourites_count"
        case friendsCount = "friends_count"
        case followersCount = "followers_count"
        case following
        case followRequestSent = "follow_request_sent"
        case geoEnabled = "geo_enabled"
        case id
        case idStr = "id_str"
        case isTranslator = "is_translator"
        case lang
        case listedCount = "listed_count"
        case location
        case name
        case notifications
        case profileBackgroundColor = "profile_background_color"
        case profileBackgroundImageUrl = "profile_background_image_url_https"
        case profileBackgroundTile = "profile_background_tile"
        case profileImageUrl = "profile_image_url_https"
        case profileLinkColor = "profile_link_color"
        case profileSidebarFillColor = "profile_sidebar_fill_color"
        case profileSidebarBorderColor = "profile_sidebar_border_color"
        case profileTextColor = "profile_text_color"
        case profileUseBackgroundImage = "profile_use_background_image"
        case protected
        case screenName = "screen_name"
        case statusesCount = "statuses_count"
        case url
        case verified
    }
}

struct ExtendedEntities: Decodable {
    
    struct Media: Decodable {
        
        struct VideoInfo: Decodable {
            
            struct Video: Decodable {
                
                let bitrate: Int?
                let url: URL
            }
            
            let variants: [Video]
        }
        
        let url: URL?
        let mediaUrl: URL
        let type: String
        let videoInfo: VideoInfo
        
        private enum CodingKeys: String, CodingKey {
            
            case url = "url"
            case mediaUrl = "media_url_https"
            case type
            case videoInfo = "video_info"
        }
    }
    
    let media: [Media]
    var type: String? {
        
        get {
            
            return media.first?.type
        }
    }
    var tweetImages: [URL]? {
        
        get {
            
            return media.map { $0.mediaUrl }
        }
    }
}

struct Retweet: Decodable {
    
    let createdAt: Date
    let entities: Entities
    let extendedEntities: ExtendedEntities?
    let favoriteCount: Int
    let favorited: Bool
    let id: UInt64
    let idStr: String
    let inReplyToStatusIdStr: String?
    let retweetCount: Int
    let retweeted: Bool
    let source: String
    let text: String
    let user: User
    var isMe: Bool? {
        
        get {
            
            guard let me = TwitterManager.shared.currentSession?.userName else {
                
                return nil
            }
            
            return me == user.name
        }
    }
    var urlStr: String {
        
        get {
            
            return "https://twitter.com/\(user.screenName)/status/\(idStr)"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        
        case createdAt = "created_at"
        case entities
        case extendedEntities = "extended_entities"
        case favoriteCount = "favorite_count"
        case favorited
        case id
        case idStr = "id_str"
        case retweetCount = "retweet_count"
        case inReplyToStatusIdStr = "in_reply_to_status_id_str"
        case retweeted
        case source
        case user
        case text
    }
}

struct Tweet: Decodable {
    
    let createdAt: Date
    let entities: Entities
    let extendedEntities: ExtendedEntities?
    let favoriteCount: Int
    let favorited: Bool
    let id: UInt64
    let idStr: String
    let inReplyToStatusIdStr: String?
    let retweetCount: Int
    let retweeted: Bool
    let retweetedStatus: Retweet?
    let source: String
    let text: String
    let user: User
    var isMe: Bool? {
        
        get {
            
            guard let me = TwitterManager.shared.currentSession?.userName else {
                
                return nil
            }
            
            return me == user.name
        }
    }
    var urlStr: String {
        
        get {
            
            return "https://twitter.com/\(user.screenName)/status/\(idStr)"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        
        case createdAt = "created_at"
        case entities
        case extendedEntities = "extended_entities"
        case favoriteCount = "favorite_count"
        case favorited
        case id
        case idStr = "id_str"
        case inReplyToStatusIdStr = "in_reply_to_status_id_str"
        case retweetCount = "retweet_count"
        case retweeted
        case retweetedStatus = "retweeted_status"
        case source
        case user
        case text
    }
}

//final class TwitterUtil {
//    // MARK: login
//    class func loginTwitter(_ present: UIViewController, success: ((ACAccount?) -> Void)? = nil) {
//        let accountStore = ACAccountStore()
//        var accounts = [ACAccount]()
//        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
//        accountStore.requestAccessToAccounts(with: accountType, options: nil) { granted, _ in
//            if granted {
//                accounts = accountStore.accounts(with: accountType) as? [ACAccount] ?? []
//                if accounts.count == 0 {
//                    Utility.simpleAlert("Error: Twitterアカウントを設定してください。", presentView: present)
//                } else {
//                    self.showAndSelectTwitterAccountWithSelectionSheets(accounts, present: present, success: success)
//                }
//            } else {
//                Utility.simpleAlert("Error: Twitterアカウントへのアクセスを許可してください。", presentView: present)
//            }
//        }
//    }
//
//    // MARK: Twitterアカウントの切り替え
//    class func showAndSelectTwitterAccountWithSelectionSheets(_ accounts: [ACAccount], present: UIViewController, success: ((ACAccount?) -> Void)? = nil) {
//        // アクションシートの設定
//        let alertController = UIAlertController(title: "アカウント選択", message: "使用するTwitterアカウントを選択してください", preferredStyle: .actionSheet)
//        let saveData: UserDefaults = UserDefaults.standard
//
//        for i in 0 ..< accounts.count {
//            let account = accounts[i]
//            alertController.addAction(UIAlertAction(title: account.username, style: .default, handler: { (_) -> Void in
//                // 選択したアカウントを返す
//                for j in 0 ..< accounts.count where account == accounts[j] {
//                    print(j)
//                    saveData.set(j, forKey: Settings.Saveword.twitter)
//                    break
//                }
//                success?(account)
//            }))
//
//        }
//
//        // キャンセルボタンは何もせずにアクションシートを閉じる
//        let CanceledAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//        alertController.addAction(CanceledAction)
//
//        // iPad用
//        alertController.popoverPresentationController?.sourceView = present.view
//        alertController.popoverPresentationController?.sourceRect = CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0)
//
//        // アクションシート表示
//        present.present(alertController, animated: true, completion: nil)
//    }
//
//    // MARK: 画像がツイートに含まれているか？
//    class func isContainMedia(_ tweet: JSON) -> Bool {
//        if tweet["extended_entities"].object != nil {
//            return true
//        }
//        return false
//    }
//}

