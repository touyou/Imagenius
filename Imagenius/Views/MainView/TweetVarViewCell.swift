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
import SDWebImage

class TweetVarViewCell: SWTableViewCell {
    @IBOutlet var tweetLabel: TTTAttributedLabel!
    @IBOutlet var userIDLabel: UILabel!
    @IBOutlet var userLabel: UILabel!
    @IBOutlet var userImgView: UIImageView!
    @IBOutlet var tweetImgView: UIImageView!
    @IBOutlet var tweetSubView: UIView!
    @IBOutlet var subViewHeight: NSLayoutConstraint!
    @IBOutlet var imageCountLabel: UILabel!
    
    // TableViewCellが生成された時------------------------------------------------
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tweetLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        self.tweetLabel.extendsLinkTouchArea = false
        self.tweetLabel.linkAttributes = [
            kCTForegroundColorAttributeName: Settings.Colors.twitterColor,
            NSUnderlineStyleAttributeName: NSNumber(long: NSUnderlineStyle.StyleNone.rawValue)
        ]
        subViewHeight.constant = 0
        self.tweetImgView.userInteractionEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // TTTAttributedLabel関連----------------------------------------------------
    // mention link
    func highrightMentionsInLabel(label: TTTAttributedLabel) {
        let text: NSString = label.text!
        let mentionExpression = try? NSRegularExpression(pattern: "(?<=^|\\s)(@\\w+)", options: [])
        let matches = mentionExpression!.matchesInString(label.text!, options: [], range: NSMakeRange(0, text.length))
        for match in matches {
            let matchRange = match.rangeAtIndex(1)
            let mentionString = text.substringWithRange(matchRange)
            let user = mentionString.substringFromIndex(mentionString.startIndex.advancedBy(1))
            let linkURLString = NSString(format: "account:%@", user)
            label.addLinkToURL(NSURL(string: linkURLString as String), withRange: matchRange)
        }
    }
    // hashtag link
    func highrightHashtagsInLabel(label: TTTAttributedLabel) {
        let text: NSString = label.text!
        let mentionExpression = try? NSRegularExpression(pattern: "(?<=^|\\s)(#\\w+)", options: [])
        let matches = mentionExpression!.matchesInString(label.text!, options: [], range: NSMakeRange(0, text.length))
        for match in matches {
            let matchRange = match.rangeAtIndex(0)
            let hashtagString = text.substringWithRange(matchRange)
            let word = hashtagString.substringFromIndex(hashtagString.startIndex.advancedBy(1))
            let linkURLString = NSString(format: "https://twitter.com/hashtag/%@", word.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
            label.addLinkToURL(NSURL(string: linkURLString as String), withRange: matchRange)
        }
    }
    
    // 要素の設定-----------------------------------------------------------------
    func setOutlet(tweet: JSONValue, tweetHeight: CGFloat) {
        let userInfo = tweet["user"]
        
        self.tweetLabel.text = Utility.convertSpecialCharacters(tweet["text"].string!)
        self.highrightHashtagsInLabel(tweetLabel)
        self.highrightMentionsInLabel(tweetLabel)
        
        self.userLabel.text = userInfo["name"].string
        let userID = userInfo["screen_name"].string!
        self.userIDLabel.text = "@\(userID)"
        let userImgPath:String = userInfo["profile_image_url_https"].string!
        let userImgURL:NSURL = NSURL(string: userImgPath)!
        
        self.userImgView.sd_setImageWithURL(userImgURL, placeholderImage: UIImage(named: "user_empty"), options: SDWebImageOptions.RetryFailed)
        
        self.userImgView.layer.cornerRadius = self.userImgView.frame.size.width * 0.5
        self.userImgView.clipsToBounds = true
        
        // こっから下で画像の枚数とそれに応じたレイアウトを行う
        guard let tweetMedia = tweet["extended_entities"]["media"].array else {
            subViewHeight.constant = 0
            self.layoutIfNeeded()
            return
        }
        
        let imageCount = tweetMedia.count
        subViewHeight.constant = tweetHeight
        tweetSubView.layer.cornerRadius = tweetSubView.frame.width * 0.017
        tweetSubView.clipsToBounds = true
        tweetSubView.layer.borderColor = Settings.Colors.selectedColor.CGColor
        tweetSubView.layer.borderWidth = 0.19
        let tweetImgPath:String = tweet["extended_entities"]["media"][0]["media_url"].string!
        let tweetImgURL:NSURL = NSURL(string: tweetImgPath)!
        
        self.tweetImgView.sd_setImageWithURL(tweetImgURL, placeholderImage: nil, options: SDWebImageOptions.RetryFailed)
        
        switch tweet["extended_entities"]["media"][0]["type"].string! {
        case "photo":
            imageCountLabel.text = "\(imageCount)枚の写真"
        case "video":
            imageCountLabel.text = "動画"
        case "animated_gif":
            imageCountLabel.text = "GIF"
        default:
            imageCountLabel.text = ""
        }
        self.layoutIfNeeded()
    }
}
