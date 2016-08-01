//
//  FavoriteResultViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/08/01.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

final class FavoriteResultViewController: UIViewController {
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var doneBtn: UIBarButtonItem!
    
    var selectedItem: FavoriteImage!
    var delegate: TweetViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if delegate == nil {
            doneBtn.enabled = false
        }
        
        previewImageView.image = selectedItem.image
    }
    
    @IBAction func cancelBtn() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func deleteBtn() {
        let actionCtrl = UIAlertController(title: "お気に入りからの削除", message: "削除しますか？", preferredStyle: .Alert)
        actionCtrl.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        actionCtrl.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            self.selectedItem.delete()
            self.navigationController?.popViewControllerAnimated(true)
        }))
        presentViewController(actionCtrl, animated: true, completion: nil)
    }
    
    @IBAction func pushDoneBtn() {
        if let del = delegate {
            dismissViewControllerAnimated(true, completion: {
                del.changeImage(self.selectedItem.image ?? UIImage(), data: self.selectedItem.imageData ?? NSData(), isGIF: false)
            })
        }
    }
}
