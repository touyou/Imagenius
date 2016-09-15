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
    final fileprivate let viewModel = TiqavImageViewModel()
    // Rx
    final fileprivate let disposeBag = DisposeBag()
    // UserDefaults
    final fileprivate let saveData: UserDefaults = UserDefaults.standard

    var searchWord: String = ""
    var selectedImage: UIImage?
    var selectedData: Data?
    var imageSize: CGFloat!
    var delegate: TweetViewControllerDelegate!

    // MARK: - UIViewControllerの設定
    override func viewDidLoad() {
        super.viewDidLoad()

        // AutoLayout対応のためセル調整
        imageSize = (self.view.frame.width) / 4
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
        imageCollectionView.backgroundColor = UIColor.white

        // データをロード
        viewModel.load(searchWord)

        // bind
        viewModel.dataUpdated
            .drive(onNext: {
                self.viewModel.urls = $0
                self.imageCollectionView.reloadData()
            })
            .addDisposableTo(disposeBag)

        NotificationCenter.default.addObserver(self, selector: #selector(TiqavImageViewController.changeOrient(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    func changeOrient(_ notification: Notification) {
        // AutoLayout対応のためセル調整
        imageSize = (self.view.frame.width) / 4
//        let flowLayout = KTCenterFlowLayout()
//        flowLayout.scrollDirection = .Vertical
//        flowLayout.minimumInteritemSpacing = 0
//        flowLayout.minimumLineSpacing = 0
//        flowLayout.itemSize = CGSizeMake(imageSize, imageSize)
//        imageCollectionView.collectionViewLayout = flowLayout
    }

    override func viewDidDisappear(_ animated: Bool) {
        let imageCache: SDImageCache = SDImageCache()
        imageCache.clearMemory()
        imageCache.clearDisk()
    }

    override func didReceiveMemoryWarning() {
        let imageCache: SDImageCache = SDImageCache()
        imageCache.clearMemory()
        imageCache.clearDisk()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toResultView" {
            let resultView = segue.destination as? ResultViewController ?? ResultViewController()
            resultView.image = self.selectedImage
            resultView.data = self.selectedData
            resultView.delegate = self.delegate
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }


    // MARK: - ボタン関連
    // MARK: キャンセルのボタン
    @IBAction func cancelButton() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - CollectionViewまわりの設定
extension TiqavImageViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    // MARK: 画像を選択したら
    func  collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        SDWebImageDownloader.shared().downloadImage(with: viewModel.urls[(indexPath as NSIndexPath).row] as URL, options: SDWebImageDownloaderOptions.useNSURLCache, progress: {
            (a: Int, b: Int) -> Void in
            // 何回もクリックされるのを防ぐ
            self.imageCollectionView.allowsSelection = false
            self.title = "loading..."
            }, completed: {
                (a: UIImage?, b: Data?, c: Error?, d: Bool) -> Void in
                self.selectedImage = a
                self.selectedData = b
                self.imageCollectionView.allowsSelection = true
                self.title = "\(self.searchWord)の検索結果"
                self.performSegue(withIdentifier: "toResultView", sender: nil)
        })
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: imageSize, height: imageSize)
    }
}

extension TiqavImageViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    // DZNEmptyDataSetの設定
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "該当する画像が見つかりませんでした。"
        let font = UIFont.systemFont(ofSize: 20)
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
    }
}
