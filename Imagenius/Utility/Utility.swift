//
//  Utility.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import Foundation
import UIKit
import Accounts

final class Utility {
    // MARK: - UI関連
    // MARK: 単純なアラートをつくる関数
    class func simpleAlert(titleString: String, presentView: UIViewController) {
        let alertController = UIAlertController(title: titleString, message: nil, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        presentView.presentViewController(alertController, animated: true, completion: nil)
    }
    // MARK: Safariで開く
    class func openWebView(url: NSURL) {
        let saveData: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        saveData.setObject(url.absoluteString, forKey: Settings.Saveword.url)
    }
    // MARK: share
    class func shareSome(url: NSURL, text: String? = nil, presentView: UIViewController) {
        let activityItems: [AnyObject]!
        if text != nil {
            activityItems = [url, text!]
        } else {
            activityItems = [url]
        }
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        let excludedActivityTypes = [UIActivityTypePostToWeibo, UIActivityTypePostToTencentWeibo]
        activityVC.excludedActivityTypes = excludedActivityTypes
        // iPad用
        activityVC.popoverPresentationController?.sourceView = presentView.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0)
        presentView.presentViewController(activityVC, animated: true, completion: nil)
    }

    // MARK: - 画像処理
    // MARK: 画像をあらかじめクロップしておく
    class func cropThumbnailImage(image: UIImage, width: Int, height: Int) -> UIImage {
        let origRef    = image.CGImage
        let origWidth  = Int(CGImageGetWidth(origRef))
        let origHeight = Int(CGImageGetHeight(origRef))
        var resizeWidth: Int = 0, resizeHeight: Int = 0

        if origWidth < origHeight {
            resizeWidth = width
            resizeHeight = origHeight * resizeWidth / origWidth
        } else {
            resizeHeight = height
            resizeWidth = origWidth * resizeHeight / origHeight
        }

        let resizeSize = CGSizeMake(CGFloat(resizeWidth), CGFloat(resizeHeight))
        UIGraphicsBeginImageContext(resizeSize)

        image.drawInRect(CGRectMake(0, 0, CGFloat(resizeWidth), CGFloat(resizeHeight)))

        let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // 切り抜き処理

        let cropRect  = CGRectMake(
            CGFloat((resizeWidth - width) / 2),
            CGFloat((resizeHeight - height) / 2),
            CGFloat(width), CGFloat(height))
        let cropRef   = CGImageCreateWithImageInRect(resizeImage.CGImage, cropRect)
        let cropImage = UIImage(CGImage: cropRef!)

        return cropImage
    }
    // MARK: 画像のリサイズ
    class func resizeImage(image: UIImage, size: CGSize) -> UIImage {
        let widthRatio = size.width / image.size.width
        let heightRatio = size.height / image.size.height
        let ratio = (widthRatio < heightRatio) ? widthRatio : heightRatio
        let resizedSize = CGSize(width: (image.size.width * ratio), height: (image.size.height * ratio))
        UIGraphicsBeginImageContext(resizedSize)
        image.drawInRect(CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    // MARK: - その他
    // MARK: HTML特殊文字を変換する
    // https://gist.github.com/mikesteele/70ae98d04fdc35cb1d5f
    class func convertSpecialCharacters(string: String) -> String {
        var newString = string
        let char_dictionary = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'"
        ]
        for (escaped_char, unescaped_char) in char_dictionary {
            newString = newString.stringByReplacingOccurrencesOfString(escaped_char, withString: unescaped_char, options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
        }
        return newString
    }
    // MARK: 日本語を含む検索語でAPIを叩くため
    class func encodeURL(text: String) -> NSURL! {
        return NSURL(string: text.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)!
    }

    class func strong<T>(obj: T?) throws -> T {
        guard let obj = obj else {
            throw "deallocated"
        }
        return obj
    }
}
extension String: ErrorType {}
