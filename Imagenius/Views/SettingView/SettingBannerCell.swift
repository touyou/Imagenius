//
//  SettingBannerCell.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/04/07.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import GoogleMobileAds

final class SettingBannerCell: UITableViewCell {
    // Google Ads関連
    @IBOutlet weak var bannerView: GADBannerView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setBanner(_ viewController: SettingTableViewController) {
        // Google Ads関連
        self.bannerView.adSize = kGADAdSizeSmartBannerPortrait
        // for test
        // self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        // for sale
        self.bannerView.adUnitID = "ca-app-pub-2853999389157478/5283774064"
        self.bannerView.rootViewController = viewController
        self.bannerView.load(GADRequest())
    }
}
