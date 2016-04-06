//
//  ImageViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import KTCenterFlowLayout
import RxSwift
import RxCocoa
import SDWebImage

class TiqavImageViewController: UIViewController, UICollectionViewDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    @IBOutlet var imageCollectionView: UICollectionView!
    
    // View Model
    final private let viewModel = TiqavImageViewModel()
    // Rx
    final private let disposeBag = DisposeBag()
    // UserDefaults
    final private let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    var searchWord: String = ""
    var selectedImage: UIImage?
    var imageSize: CGFloat!
    
    // UIViewControllerの設定----------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        // DataSourceとDelegateの設定
        imageCollectionView.dataSource = viewModel
        imageCollectionView.delegate = self
        imageCollectionView.emptyDataSetDelegate = self
        imageCollectionView.emptyDataSetSource = self
        
        // データをロード
        viewModel.load(searchWord)
        
        // bind
        viewModel.dataUpdated
            .driveNext({
                self.viewModel.urls = $0
                self.imageCollectionView.reloadData()
            })
            .addDisposableTo(disposeBag)
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
    // 画像を選択したら
    func  collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        SDWebImageDownloader.sharedDownloader().downloadImageWithURL(viewModel.urls[indexPath.row], options: SDWebImageDownloaderOptions.UseNSURLCache, progress: {
            (a: Int, b: Int) -> Void in
            // 何回もクリックされるのを防ぐ
            self.imageCollectionView.allowsSelection = false
            self.navigationController?.title = "loading..."
            }, completed: {
            (a: UIImage!, b: NSData!, c: NSError!, d: Bool!) -> Void in
            self.selectedImage = a
            self.imageCollectionView.allowsSelection = true
            self.navigationController?.title = "画像検索結果"
            self.performSegueWithIdentifier("toResultView", sender: nil)
        })
    }
    // DZNEmptyDataSetの設定
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "該当する画像が見つかりませんでした。"
        let font = UIFont.systemFontOfSize(20)
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
    }
}
