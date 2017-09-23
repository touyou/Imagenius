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
    
    var currentSession: TWTRSession?
    
    init() {
        
        Twitter.sharedInstance().start(withConsumerKey: consumerKey, consumerSecret: consumerSecret)
        
        if let userID = saveData.object(forKey: Settings.Saveword.account) as? String {
            
            currentSession = twitter.sessionStore.session(forUserID: userID) as? TWTRSession
        }
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
    
    func loadHomeTimelineTweet(count: Int, maxID: String? = nil, success: @escaping (([TweetModel])->Void), failure: ((Error?)->Void)? = nil) {
        
        guard let userID = currentSession?.userID else {
            
            failure?(nil)
            return
        }
        
        let client = TWTRAPIClient(userID: userID)
        let endpoint = "https://api.twitter.com/1.1/statuses/home_timeline.json"
        var params = [AnyHashable: Any]()
        params["count"] = count
        _ = maxID.flatMap { params["max_id"] = $0 }
        var error: NSError?
        let request = client.urlRequest(withMethod: "GET", url: endpoint, parameters: params, error: &error)

        client.sendTwitterRequest(request) { response, data, connectError in
            
            if let connectError = connectError {
                
                print(connectError)
            }
            
            do {
                
                let tweets = try JSONDecoder().decode(Array<TweetModel>.self, from: data!)
                success(tweets)
            } catch let error {
                
                print(error.localizedDescription ?? "")
            }
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
        
        let user: String
        let idStr: String
        let id: UInt64
        let indices: [Int]
        let screenName: String
        
        private enum CodingKeys: String, CodingKey {
            
            case user
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
    
    let name: String
    let profileSidebarFillColor: String
    let profileBackgroundTile: Bool
    let profileSidebarBorderColor: String
    let createdAt: Date
    let location: String
    let followRequestSent: Bool
    let idStr: String
    let isTranslator: Bool
    let profileLinkColor: String
    let entities: UserEntities
    let defaultProfile: Bool
    let url: URL
    let contributorsEnabled: Bool
    let favouritesCount: Int
    let profileImageUrl: URL
    let id: UInt64
    let listedCount: Int
    let profileUseBackgroundImage: Bool
    let profileTextColor: String
    let followersCount: Int
    let lang: String
    let protected: Bool
    let geoEnabled: Bool
    let notifications: Bool
    let description: String
    let profileBackgroundColor: String
    let verified: Bool
    let profileBackgroundImageUrl: URL
    let statusesCount: Int
    let defaultProfileImage: Bool
    let friendsCount: Int
    let following: Bool
    let showAllInlineMedia: Bool
    let screenName: String
    
    private enum CodingKeys: String, CodingKey {
        
        case name
        case profileSidebarFillColor = "profile_sidebar_fill_color"
        case profileBackgroundTile = "profile_background_tile"
        case profileSidebarBorderColor = "profile_sidebar_border_color"
        case createdAt = "created_at"
        case location
        case followRequestSent = "follow_request_sent"
        case idStr = "id_str"
        case isTranslator = "is_translator"
        case profileLinkColor = "profile_link_color"
        case entities
        case defaultProfile = "default_profile"
        case url
        case contributorsEnabled = "contributors_enabled"
        case favouritesCount = "favourites_count"
        case profileImageUrl = "profile_image_url_https"
        case id
        case listedCount = "listed_count"
        case profileUseBackgroundImage = "profile_use_background_image"
        case profileTextColor = "profile_text_color"
        case followersCount = "followers_count"
        case lang
        case protected
        case geoEnabled = "geo_enabled"
        case notifications
        case description
        case profileBackgroundColor = "profile_background_color"
        case verified
        case profileBackgroundImageUrl = "profile_background_image_url_https"
        case statusesCount = "statuses_count"
        case defaultProfileImage = "default_profile_image"
        case friendsCount = "friends_count"
        case following
        case showAllInlineMedia = "show_all_inline_media"
        case screenName = "screen_name"
    }
}

struct ExtendedEntities: Decodable {
    
    struct Media: Decodable {
        
        let mediaUrl: URL
        let type: String
        
        private enum CodingKeys: String, CodingKey {
            
            case mediaUrl = "media_url"
            case type
        }
    }
    
    let media: [Media]
}

struct TweetModel: Decodable {
    
    let createdAt: Date
    let favoritedCount: Int
    let favorited: Bool
    let idStr: String
    let entities: Entities
    let text: String
    let id: UInt64
    let retweetCount: Int
    let retweeted: Bool
    let source: String
    let user: User
    let extendedEntities: ExtendedEntities?
    
    private enum CodingKeys: String, CodingKey {
        
        case createdAt = "created_at"
        case favoritedCount = "favorited_count"
        case favorited
        case idStr = "id_str"
        case entities
        case text
        case id
        case retweetCount = "retweet_count"
        case retweeted
        case source
        case user
        case extendedEntities = "extended_entities"
    }
}

final class TwitterUtil {
    // MARK: login
    class func loginTwitter(_ present: UIViewController, success: ((ACAccount?) -> Void)? = nil) {
        let accountStore = ACAccountStore()
        var accounts = [ACAccount]()
        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: accountType, options: nil) { granted, _ in
            if granted {
                accounts = accountStore.accounts(with: accountType) as? [ACAccount] ?? []
                if accounts.count == 0 {
                    Utility.simpleAlert("Error: Twitterアカウントを設定してください。", presentView: present)
                } else {
                    self.showAndSelectTwitterAccountWithSelectionSheets(accounts, present: present, success: success)
                }
            } else {
                Utility.simpleAlert("Error: Twitterアカウントへのアクセスを許可してください。", presentView: present)
            }
        }
    }

    // MARK: Twitterアカウントの切り替え
    class func showAndSelectTwitterAccountWithSelectionSheets(_ accounts: [ACAccount], present: UIViewController, success: ((ACAccount?) -> Void)? = nil) {
        // アクションシートの設定
        let alertController = UIAlertController(title: "アカウント選択", message: "使用するTwitterアカウントを選択してください", preferredStyle: .actionSheet)
        let saveData: UserDefaults = UserDefaults.standard

        for i in 0 ..< accounts.count {
            let account = accounts[i]
            alertController.addAction(UIAlertAction(title: account.username, style: .default, handler: { (_) -> Void in
                // 選択したアカウントを返す
                for j in 0 ..< accounts.count where account == accounts[j] {
                    print(j)
                    saveData.set(j, forKey: Settings.Saveword.twitter)
                    break
                }
                success?(account)
            }))

        }

        // キャンセルボタンは何もせずにアクションシートを閉じる
        let CanceledAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(CanceledAction)

        // iPad用
        alertController.popoverPresentationController?.sourceView = present.view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0)

        // アクションシート表示
        present.present(alertController, animated: true, completion: nil)
    }

    // MARK: 画像がツイートに含まれているか？
    class func isContainMedia(_ tweet: JSON) -> Bool {
        if tweet["extended_entities"].object != nil {
            return true
        }
        return false
    }
}
