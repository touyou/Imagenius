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

final class TiqavImageViewController: UIViewController {
    @IBOutlet weak var imageCollectionView: UICollectionView!

    // View Model
    final private let viewModel = TiqavImageViewModel()
    // Rx
    final private let disposeBag = DisposeBag()
    // UserDefaults
    final private let saveData: NSUserDefaults = NSUserDefaults.standardUserDefaults()

    var searchWord: String = ""
    var selectedImage: UIImage?
    var selectedData: NSData?
    var imageSize: CGFloat!
    var delegate: TweetViewControllerDelegate!

    // MARK: - UIViewControllerの設定
    override func viewDidLoad() {
        super.viewDidLoad()

        // AutoLayout対応のためセル調整
//        imageSize = (self.view.frame.width) / 4
//        let flowLayout = KTCenterFlowLayout()
//        flowLayout.scrollDirection = .Vertical
//        flowLayout.minimumInteritemSpacing = 0
//        flowLayout.minimumLineSpacing = 0
//        flowLayout.itemSize = CGSizeMake(imageSize, imageSize)
//        imageCollectionView.collectionViewLayout = flowLayout

        self.title = "\(searchWord)の検索結果"

        // DataSourceとDelegateの設定
        imageCollectionView.dataSource = viewModel
        imageCollectionView.delegate = self
        imageCollectionView.emptyDataSetDelegate = self
        imageCollectionView.emptyDataSetSource = self
        imageCollectionView.backgroundColor = UIColor.whiteColor()

        // データをロード
        viewModel.load(searchWord)

        // bind
        viewModel.dataUpdated
            .driveNext({
                self.viewModel.urls = $0
                self.imageCollectionView.reloadData()
            })
            .addDisposableTo(disposeBag)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TiqavImageViewController.changeOrient(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }

    func changeOrient(notification: NSNotification) {
        // AutoLayout対応のためセル調整
//        imageSize = (self.view.frame.width) / 4
//        let flowLayout = KTCenterFlowLayout()
//        flowLayout.scrollDirection = .Vertical
//        flowLayout.minimumInteritemSpacing = 0
//        flowLayout.minimumLineSpacing = 0
//        flowLayout.itemSize = CGSizeMake(imageSize, imageSize)
//        imageCollectionView.collectionViewLayout = flowLayout
    }

    override func viewDidDisappear(animated: Bool) {
        let imageCache: SDImageCache = SDImageCache()
        imageCache.clearMemory()
        imageCache.clearDisk()
    }

    override func didReceiveMemoryWarning() {
        let imageCache: SDImageCache = SDImageCache()
        imageCache.clearMemory()
        imageCache.clearDisk()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toResultView" {
            let resultView = segue.destinationViewController as? ResultViewController ?? ResultViewController()
            resultView.image = self.selectedImage
            resultView.data = self.selectedData
            resultView.delegate = self.delegate
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }


    // MARK: - ボタン関連
    // MARK: キャンセルのボタン
    @IBAction func cancelButton() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - CollectionViewまわりの設定
extension TiqavImageViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    // MARK: 画像を選択したら
    func  collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        SDWebImageDownloader.sharedDownloader().downloadImageWithURL(viewModel.urls[indexPath.row], options: SDWebImageDownloaderOptions.UseNSURLCache, progress: {
            (a: Int, b: Int) -> Void in
            // 何回もクリックされるのを防ぐ
            self.imageCollectionView.allowsSelection = false
            self.title = "loading..."
            }, completed: {
                (a: UIImage!, b: NSData!, c: NSError!, d: Bool!) -> Void in
                self.selectedImage = a
                self.selectedData = b
                self.imageCollectionView.allowsSelection = true
                self.title = "\(self.searchWord)の検索結果"
                self.performSegueWithIdentifier("toResultView", sender: nil)
        })
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(imageSize, imageSize)
    }
}

extension TiqavImageViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    // DZNEmptyDataSetの設定
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "該当する画像が見つかりませんでした。"
        let font = UIFont.systemFontOfSize(20)
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
    }
}
