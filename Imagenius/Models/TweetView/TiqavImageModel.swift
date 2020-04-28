//
//  TiqavImageModel.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/04/06.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Alamofire
import SwiftyJSON

class TiqavImageModel: NSObject {
    final let urls = Variable([URL]())

    fileprivate let apiKey = "AIzaSyCecfACGPjcjQ7G397MXT__F1Ks5-sl0PA"
    fileprivate let csId = "009645097602719053319:kgqwkrkiiew"

    final func request(_ searchWord: String) {
        let text = "http://api.tiqav.com/search.json?q="+searchWord
//        let text = "https://www.googleapis.com/customsearch/v1?key=\(apiKey)&cx=\(csId)&searchType=image&q=\(searchWord)"
        AF.request(Utility.encodeURL(text)).responseJSON(completionHandler: { response in
            switch response.result {
            case .success(let value):
                let json = SwiftyJSON.JSON(value)
                json.forEach({(_, json) in
                    let url = URL(string: "http://img.tiqav.com/" + json["id"].rawString()! + "." + json["ext"].rawString()!)
                    self.urls.value.append(url!)
                })
            case .failure(let error):
                print("error: \(error)")
            }
        })
    }
}
