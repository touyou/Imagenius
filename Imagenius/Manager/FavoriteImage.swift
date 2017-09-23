//
//  FavoriteImage.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/08/01.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import RealmSwift

// MARK: - 画像保存用のクラス for Realm
// 参考：http://qiita.com/_ha1f/items/593ca4f9c97ae697fc75
class FavoriteImage: Object {
    static let realm = try! Realm()
    
    @objc dynamic fileprivate var id = 0
    @objc dynamic fileprivate var _image: UIImage?
    @objc dynamic var image: UIImage? {
        set {
            self._image = newValue
            if let value = newValue {
                self.imageData = UIImagePNGRepresentation(value)
            }
        }
        get {
            if let image = self._image {
                return image
            }
            if let data = self.imageData {
                self._image = UIImage(data: data)
                return self._image
            }
            return nil
        }
    }
    @objc dynamic var imageData: Data?
    
    // MARK: - Realm用の設定
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["image", "_image"]
    }
    
    // MARK: - ユーティリティーメソッド
    static func create() -> FavoriteImage {
        let favImage = FavoriteImage()
        favImage.id = lastId()
        return favImage
    }
    
    static func loadAll() -> [FavoriteImage] {
        // let favImages = realm.allObjects(ofType: FavoriteImage.self).sorted(onProperty: "id", ascending: false)
        let favImages = realm.objects(FavoriteImage.self).sorted(byKeyPath: "id")
        var ret = [FavoriteImage]()
        for favImage in favImages {
            ret.append(favImage)
        }
        return ret
    }
    
    static func lastId() -> Int {
        //if let favImage = realm.allObjects(ofType: FavoriteImage.self).last {
        if let favImage = realm.objects(FavoriteImage.self).last {
            return favImage.id + 1
        } else {
            return 1
        }
    }
    
    // MARK: - 保存と削除
    func save() {
        try! FavoriteImage.realm.write {
            FavoriteImage.realm.add(self)
        }
    }
    
    func delete() {
        try! FavoriteImage.realm.write {
            FavoriteImage.realm.delete(self)
        }
    }
}
