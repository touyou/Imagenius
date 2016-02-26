//
//  TweetViewCell.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/22.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS
import TTTAttributedLabel
import SWTableViewCell

class TweetViewCell: SWTableViewCell, TTTAttributedLabelDelegate {
    @IBOutlet var tweetLabel: TTTAttributedLabel!
    @IBOutlet var userIDLabel: UILabel!
    @IBOutlet var userLabel: UILabel!
    @IBOutlet var userImgView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tweetLabel.delegate = self
        self.tweetLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        self.tweetLabel.extendsLinkTouchArea = false
        self.tweetLabel.linkAttributes = [
            kCTForegroundColorAttributeName: Settings.Colors.twitterColor,
            NSUnderlineStyleAttributeName: NSNumber(long: NSUnderlineStyle.StyleNone.rawValue)
        ]
    }
    
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
    }
    
    // MARK: - TTTAttributedLabelDelegate
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
            let linkURLString = NSString(format: "https://twitter.com/#%@", word)
            label.addLinkToURL(NSURL(string: linkURLString as String), withRange: matchRange)
        }
    }
}
