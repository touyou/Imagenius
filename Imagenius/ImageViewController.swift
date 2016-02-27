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
import KTCenterFlowLayout

class ImageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    @IBOutlet var imageCollectionView: UICollectionView!
    var searchWord: String = ""
    var reqs: [NSURLRequest] = []
    var selectedImage: UIImage?
    var imageSize: CGFloat!
    
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
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
    
    // NavigationBarまわり
    @IBAction func cancelButton() {
        dismissViewControllerAnimated(true, completion: nil)
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
            cell.imageView.image = Utility.cropThumbnailImage(image!, w: Int(self.imageSize), h: Int(self.imageSize))
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
    // 検索ワードを渡す
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toResultView" {
            let resultView = segue.destinationViewController as! ResultViewController
            resultView.image = self.selectedImage
        }
    }
    // CollectionViewのAutoLayout対応
}
