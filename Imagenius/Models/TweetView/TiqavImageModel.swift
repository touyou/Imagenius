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
        Alamofire.request(Utility.encodeURL(text)).responseJSON(completionHandler: {
            response in
            guard let object = response.result.value else {
                return
            }
            let json = SwiftyJSON.JSON(object)
//            print(json)
            json.forEach({(_, json) in
                let url = URL(string: "http://img.tiqav.com/" + String(describing: json["id"]) + "." + json["ext"].string!)
                self.urls.value.append(url!)
            })
//            if json["items"].array != nil {
//                json["items"].array?.forEach { json in
//                    let url = NSURL(string: json["link"].string!)
//                    self.urls.value.append(url!)
//                }
//            }
        })
    }
}
