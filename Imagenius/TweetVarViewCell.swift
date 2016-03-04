//
//  TweetVarViewCell.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/04.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS
import TTTAttributedLabel
import SWTableViewCell

class TweetVarViewCell: SWTableViewCell, TTTAttributedLabelDelegate {
    @IBOutlet var tweetLabel: TTTAttributedLabel!
    @IBOutlet var userIDLabel: UILabel!
    @IBOutlet var userLabel: UILabel!
    @IBOutlet var userImgView: UIImageView!
    @IBOutlet var tweetSubView: UIView!
    @IBOutlet var subViewHeight: NSLayoutConstraint!
    
    var tweetImageURL: [NSURL]?
    
    // TableViewCellが生成された時------------------------------------------------
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tweetLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        self.tweetLabel.extendsLinkTouchArea = false
        self.tweetLabel.delegate = self
        self.tweetLabel.linkAttributes = [
            kCTForegroundColorAttributeName: Settings.Colors.twitterColor,
            NSUnderlineStyleAttributeName: NSNumber(long: NSUnderlineStyle.StyleNone.rawValue)
        ]
        
        // self.tweetImgView.userInteractionEnabled = true
    }
    
    // TTTAttributedLabel関連----------------------------------------------------
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        Utility.openWebView(url)
    }
    // mention link
    func highrightMentionsInLabel(label: TTTAttributedLabel) {
        let text: NSString = label.text!
        let mentionExpression = try? NSRegularExpression(pattern: "(?<=^|\\s)(@\\w+)", options: [])
        let matches = mentionExpression!.matchesInString(label.text!, options: [], range: NSMakeRange(0, text.length))
        for match in matches {
            let matchRange = match.rangeAtIndex(1)
            let mentionString = text.substringWithRange(matchRange)
            let user = mentionString.substringFromIndex(mentionString.startIndex.advancedBy(1))
            let linkURLString = NSString(format: "https://twitter.com/%@", user)
            label.addLinkToURL(NSURL(string: linkURLString as String), withRange: matchRange)
        }
    }
    // hashtag link
    func highrightHashtagsInLabel(label: TTTAttributedLabel) {
        let text: NSString = label.text!
        let mentionExpression = try? NSRegularExpression(pattern: "(?<=^|\\s)(#\\w+)", options: [])
        let matches = mentionExpression!.matchesInString(label.text!, options: [], range: NSMakeRange(0, text.length))
        for match in matches {
            let matchRange = match.rangeAtIndex(1)
            let hashtagString = text.substringWithRange(matchRange)
            let word = hashtagString.substringFromIndex(hashtagString.startIndex.advancedBy(1))
            let linkURLString = NSString(format: "https://twitter.com/hashtag/%@", word)
            label.addLinkToURL(NSURL(string: linkURLString as String), withRange: matchRange)
        }
    }
    
    // 要素の設定-----------------------------------------------------------------
    func setOutlet(tweet: JSONValue) {
        let userInfo = tweet["user"]
        
        self.tweetLabel.text = Utility.convertSpecialCharacters(tweet["text"].string!)
        self.highrightHashtagsInLabel(tweetLabel)
        self.highrightMentionsInLabel(tweetLabel)
        
        self.userLabel.text = userInfo["name"].string
        let userID = userInfo["screen_name"].string!
        self.userIDLabel.text = "@\(userID)"
        let userImgPath:String = userInfo["profile_image_url_https"].string!
        let userImgURL:NSURL = NSURL(string: userImgPath)!
        let userImgPathData:NSData? = NSData(contentsOfURL: userImgURL)
        if userImgPathData != nil {
            self.userImgView.image = UIImage(data: userImgPathData!)
        } else {
            self.userImgView.image = UIImage(named: "user_empty")
        }
        self.userImgView.layer.cornerRadius = self.userImgView.frame.size.width * 0.5
        self.userImgView.clipsToBounds = true
        
        // こっから下で画像の枚数とそれに応じたレイアウトを行う
        let imageCount:Int = tweet["extended_entities"]["media"].object!.count
        switch imageCount {
        case 0:
            subViewHeight.constant = 0
        case 1:
            initSubView(1)
        case 2:
            initSubView(2)
        case 3:
            initSubView(3)
        case 4:
            initSubView(4)
        default:
            break
        }
        
        // let tweetImgPath:String = tweet["extended_entities"]["media"][0]["media_url"].string!
        // let tweetImgURL:NSURL = NSURL(string: tweetImgPath)!
        // let tweetImgPathData:NSData = NSData(contentsOfURL: tweetImgURL)!
        // self.tweetImgView.image = Utility.cropThumbnailImage(UIImage(data: tweetImgPathData)!, w: Int(self.tweetImgView.frame.width), h: Int(self.tweetImgView.frame.height))
        // self.tweetImageURL = NSURL(string: tweet["extended_entities"]["media"][0]["url"].string!)
    }
    
    // Utility------------------------------------------------------------------
    func initSubView(num: Int) {
        subViewHeight.constant = tweetSubView.frame.width / 3 * 2
        let h = tweetSubView.frame.width / 3 * 2; let w = tweetSubView.frame.width
        tweetSubView.layer.cornerRadius = w * 0.1
        tweetSubView.clipsToBounds = true
        
        for var i = 0; i < num; i++ {
            if num == 1 {
                let tweetImageView = UIImageView()
                // tweetImageView
            }
        }
    }
}
