//
//  TiqavImageViewModel.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/04/06.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SDWebImage

class TiqavImageViewModel: NSObject, UICollectionViewDataSource {
    
    // ViewModel
    final private var model = TiqavImageModel()
    // ImageURLs
    final var urls = [NSURL]()
    // Rx
    final private(set) var dataUpdated: Driver<[NSURL]> = Driver.never()
    
    override init() {
        super.init()
        dataUpdated = model.urls.asDriver()
    }
    
    func load(word: String) {
        model.request(word)
    }
    
    // MARK: -CollectionView
    // 画像の数
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urls.count
    }
    // 入れるもの
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: TiqavImageViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! TiqavImageViewCell
        let url = urls[indexPath.row]
        cell.imageView.sd_setImageWithURL(url, placeholderImage: nil, options: SDWebImageOptions.RetryFailed)
        return cell
    }

}
