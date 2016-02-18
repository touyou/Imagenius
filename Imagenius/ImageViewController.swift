//
//  ImageViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ImageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet var imageCollectionView: UICollectionView!
    var searchWord: String = ""
    var reqs: [NSURLRequest] = []
    var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
        
        tiqav()
    }
    // Tiqav.comでの検索
    func tiqav() {
        let text = "http://api.tiqav.com/search.json?q="+searchWord
        Alamofire.request(.GET, encodeURL(text), parameters: nil).responseJSON(completionHandler: {
            response in
            guard let object = response.result.value else {
                return
            }
            let json = JSON(object)
            json.forEach({(_, json) in
                let url = NSURL(string: "http://img.tiqav.com/" + String(json["id"]) + "." + json["ext"].string!)
                let req = NSURLRequest(URL: url!)
                self.reqs.append(req)
            })
            // CollectionViewをリロードする
            self.imageCollectionView.reloadData()
        })
    }
    // 日本語を含む検索語でAPIを叩くため
    func encodeURL(text: String) -> NSURL! {
        return NSURL(string: text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)!
    }
    // 画面を閉じる時
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // selectedImageを渡す
        if segue.identifier == "toResultView" {
            let resultViewCtrl = segue.destinationViewController as! ResultViewController
            resultViewCtrl.image = self.selectedImage
        }
    }
    
    
    // NavigationBarまわり
    @IBAction func cancelButton() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // CollectionViewまわりの設定
    // セクション数
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    // 画像の数
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return reqs.count
    }
    // 入れるもの
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: ImageViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ImageViewCell
        NSURLConnection.sendAsynchronousRequest(reqs[indexPath.row], queue: NSOperationQueue.mainQueue(), completionHandler: {(res, data, err) in
            let image = UIImage(data: data!)
            cell.imageView.image = self.cropThumbnailImage(image!, w: 106, h: 106)
        })
        return cell
    }
    // 画像を選択したら
    func  collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        NSURLConnection.sendAsynchronousRequest(reqs[indexPath.row], queue: NSOperationQueue.mainQueue(), completionHandler: {(res, data, err) in
            self.selectedImage = UIImage(data: data!)
        })
        performSegueWithIdentifier("toResultView", sender: nil)
    }
    // 画像をあらかじめリサイズしておく
    func cropThumbnailImage(image :UIImage, w:Int, h:Int) ->UIImage {
        let origRef    = image.CGImage;
        let origWidth  = Int(CGImageGetWidth(origRef))
        let origHeight = Int(CGImageGetHeight(origRef))
        var resizeWidth:Int = 0, resizeHeight:Int = 0
        
        if (origWidth < origHeight) {
            resizeWidth = w
            resizeHeight = origHeight * resizeWidth / origWidth
        } else {
            resizeHeight = h
            resizeWidth = origWidth * resizeHeight / origHeight
        }
        
        let resizeSize = CGSizeMake(CGFloat(resizeWidth), CGFloat(resizeHeight))
        UIGraphicsBeginImageContext(resizeSize)
        
        image.drawInRect(CGRectMake(0, 0, CGFloat(resizeWidth), CGFloat(resizeHeight)))
        
        let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // 切り抜き処理
        
        let cropRect  = CGRectMake(
            CGFloat((resizeWidth - w) / 2),
            CGFloat((resizeHeight - h) / 2),
            CGFloat(w), CGFloat(h))
        let cropRef   = CGImageCreateWithImageInRect(resizeImage.CGImage, cropRect)
        let cropImage = UIImage(CGImage: cropRef!)
        
        return cropImage
    }

}
