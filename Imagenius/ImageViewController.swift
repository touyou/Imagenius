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
import DZNEmptyDataSet
import KTCenterFlowLayout

class ImageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    @IBOutlet var imageCollectionView: UICollectionView!
    
    var searchWord: String = ""
    var reqs: [NSURLRequest] = []
    var selectedImage: UIImage?
    var imageSize: CGFloat!
    
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    // UIViewControllerの設定----------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
        
        if saveData.objectForKey(Settings.Saveword.search) != nil {
            searchWord = saveData.objectForKey(Settings.Saveword.search) as! String
        }
        
        // AutoLayout対応のためセル調整
        imageSize = (self.view.frame.width) / 4
        let flowLayout = KTCenterFlowLayout()
        flowLayout.scrollDirection = .Vertical
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.itemSize = CGSizeMake(imageSize, imageSize)
        imageCollectionView.collectionViewLayout = flowLayout
        
        self.imageCollectionView.emptyDataSetDelegate = self
        self.imageCollectionView.emptyDataSetSource = self
        
        tiqav()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toResultView" {
            let resultView = segue.destinationViewController as! ResultViewController
            resultView.image = self.selectedImage
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    // ボタン関連-----------------------------------------------------------------
    // キャンセルのボタン
    @IBAction func cancelButton() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // CollectionViewまわりの設定-------------------------------------------------
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
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let  task = session.dataTaskWithRequest(reqs[indexPath.row]){(data, res, err)->Void in
            dispatch_async(dispatch_get_main_queue(), {
                let image = UIImage(data: data!)
                cell.imageView.image = Utility.cropThumbnailImage(image!, w: Int(self.imageSize), h: Int(self.imageSize))
            })
        }
        task.resume()
        return cell
    }
    // 画像を選択したら
    func  collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let  task = session.dataTaskWithRequest(reqs[indexPath.row], completionHandler: {(data, res, err)->Void in
            self.selectedImage = UIImage(data: data!)
            dispatch_async(dispatch_get_main_queue(), {
                self.performSegueWithIdentifier("toResultView", sender: nil)
            })
        })
        task.resume()
    }
    // DZNEmptyDataSetの設定
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "該当する画像が見つかりませんでした。"
        let font = UIFont.systemFontOfSize(20)
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
    }
    
    // Utility------------------------------------------------------------------
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
        return NSURL(string: text.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)!
    }
}
