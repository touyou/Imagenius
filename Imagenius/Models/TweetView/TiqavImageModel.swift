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
    final let urls = Variable([NSURL]())
    
    final func request(searchWord: String) {
        let text = "http://api.tiqav.com/search.json?q="+searchWord
        Alamofire.request(.GET, Utility.encodeURL(text), parameters: nil).responseJSON(completionHandler: {
            response in
            guard let object = response.result.value else {
                return
            }
            let json = SwiftyJSON.JSON(object)
            json.forEach({(_, json) in
                let url = NSURL(string: "http://img.tiqav.com/" + String(json["id"]) + "." + json["ext"].string!)
                self.urls.value.append(url!)
            })
        })
    }
}
