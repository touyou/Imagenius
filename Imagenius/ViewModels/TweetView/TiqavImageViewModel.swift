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

final class TiqavImageViewModel: NSObject {

    // ViewModel
    final fileprivate var model = TiqavImageModel()
    // ImageURLs
    final var urls = [URL]()
    // Rx
    final fileprivate(set) var dataUpdated: Driver<[URL]> = Driver.never()

    override init() {
        super.init()
        dataUpdated = model.urls.asDriver()
    }

    func load(_ word: String) {
        model.request(word)
    }

}

// MARK: - CollectionView
extension TiqavImageViewModel: UICollectionViewDataSource {
    // MARK: 画像の数
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urls.count
    }
    // MARK: 入れるもの
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: TiqavImageViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as? TiqavImageViewCell ?? TiqavImageViewCell()
        let url = urls[indexPath.row]
        cell.imageView.contentMode = .scaleAspectFill
        cell.imageView.sd_setImage(with: url, placeholderImage: nil, options: SDWebImageOptions.retryFailed)
        return cell
    }
}
