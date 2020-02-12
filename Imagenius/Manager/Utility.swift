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
    class func simpleAlert(_ titleString: String, presentView: UIViewController) {
        let alertController = UIAlertController(title: titleString, message: nil, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        presentView.present(alertController, animated: true, completion: nil)
    }
    // MARK: Safariで開く
    class func openWebView(_ url: URL) {
        let saveData: UserDefaults = UserDefaults.standard
        saveData.set(url.absoluteString, forKey: Settings.Saveword.url)
    }
    // MARK: share
    class func shareSome(_ url: URL, text: String? = nil, presentView: UIViewController) {
        let activityItems: [AnyObject]!
        if text != nil {
            activityItems = [url as AnyObject, text! as AnyObject]
        } else {
            activityItems = [url as AnyObject]
        }
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        let excludedActivityTypes = [UIActivity.ActivityType.postToWeibo, UIActivity.ActivityType.postToTencentWeibo]
        activityVC.excludedActivityTypes = excludedActivityTypes
        // iPad用
        activityVC.popoverPresentationController?.sourceView = presentView.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0)
        presentView.present(activityVC, animated: true, completion: nil)
    }

    // MARK: - 画像処理
    // MARK: 画像をあらかじめクロップしておく
    class func cropThumbnailImage(_ image: UIImage, width: Int, height: Int) -> UIImage {
        let origRef    = image.cgImage
        let origWidth  = Int((origRef?.width)!)
        let origHeight = Int((origRef?.height)!)
        var resizeWidth: Int = 0, resizeHeight: Int = 0

        if origWidth < origHeight {
            resizeWidth = width
            resizeHeight = origHeight * resizeWidth / origWidth
        } else {
            resizeHeight = height
            resizeWidth = origWidth * resizeHeight / origHeight
        }

        let resizeSize = CGSize(width: CGFloat(resizeWidth), height: CGFloat(resizeHeight))
        UIGraphicsBeginImageContext(resizeSize)

        image.draw(in: CGRect(x: 0, y: 0, width: CGFloat(resizeWidth), height: CGFloat(resizeHeight)))

        let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // 切り抜き処理

        let cropRect  = CGRect(
            x: CGFloat((resizeWidth - width) / 2),
            y: CGFloat((resizeHeight - height) / 2),
            width: CGFloat(width), height: CGFloat(height))
        let cropRef   = resizeImage?.cgImage?.cropping(to: cropRect)
        let cropImage = UIImage(cgImage: cropRef!)

        return cropImage
    }
    // MARK: 画像のリサイズ
    class func resizeImage(_ image: UIImage, size: CGSize) -> UIImage {
        let widthRatio = size.width / image.size.width
        let heightRatio = size.height / image.size.height
        let ratio = (widthRatio < heightRatio) ? widthRatio : heightRatio
        let resizedSize = CGSize(width: (image.size.width * ratio), height: (image.size.height * ratio))
        UIGraphicsBeginImageContext(resizedSize)
        image.draw(in: CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage!
    }

    // MARK: - その他
    // MARK: HTML特殊文字を変換する
    // https://gist.github.com/mikesteele/70ae98d04fdc35cb1d5f
    class func convertSpecialCharacters(_ string: String) -> String {
        var newString = string
        let char_dictionary = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'"
        ]
        for (escaped_char, unescaped_char) in char_dictionary {
            newString = newString.replacingOccurrences(of: escaped_char, with: unescaped_char, options: NSString.CompareOptions.regularExpression, range: nil)
        }
        return newString
    }
    // MARK: 日本語を含む検索語でAPIを叩くため
    class func encodeURL(_ text: String) -> URL! {
        return URL(string: text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)!
    }

    class func strong<T>(_ obj: T?) throws -> T {
        guard let obj = obj else {
            throw "deallocated"
        }
        return obj
    }
}
