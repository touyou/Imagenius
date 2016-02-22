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
import SwifteriOS

class ImageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet var imageCollectionView: UICollectionView!
    var searchWord: String = ""
    var tweetText: String?
    var reqs: [NSURLRequest] = []
    var selectedImage: UIImage?
    
    var swifter:Swifter!
    
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
            let json = SwiftyJSON.JSON(object)
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
            let resultView = segue.destinationViewController as! ResultViewController
            resultView.image = self.selectedImage
            resultView.tweetText = self.tweetText
            resultView.searchWord = self.searchWord
            resultView.swifter = self.swifter
        } else if segue.identifier == "backTweetView" {
            let tweetView = segue.destinationViewController as! TweetViewController
            tweetView.tweetText = self.tweetText
            tweetView.swifter = self.swifter
        }
    }
    
    
    // NavigationBarまわり
    @IBAction func cancelButton() {
        performSegueWithIdentifier("backTweetView", sender: nil)
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
        let cell: ImageViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! ImageViewCell
        NSURLConnection.sendAsynchronousRequest(reqs[indexPath.row], queue: NSOperationQueue.mainQueue(), completionHandler: {(res, data, err) in
            let image = UIImage(data: data!)
            cell.imageView.image = Utility.cropThumbnailImage(image!, w: 106, h: 106)
        })
        return cell
    }
    // 画像を選択したら
    func  collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        NSURLConnection.sendAsynchronousRequest(reqs[indexPath.row], queue: NSOperationQueue.mainQueue(), completionHandler: {(res, data, err) in
            self.selectedImage = UIImage(data: data!)
            self.performSegueWithIdentifier("toResultView", sender: nil)
        })
    }

}
