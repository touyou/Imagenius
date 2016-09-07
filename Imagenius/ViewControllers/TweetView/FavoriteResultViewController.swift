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
            doneBtn.isEnabled = false
        }
        
        previewImageView.image = selectedItem.image
    }
    
    @IBAction func cancelBtn() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteBtn() {
        let actionCtrl = UIAlertController(title: "お気に入りからの削除", message: "削除しますか？", preferredStyle: .alert)
        actionCtrl.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionCtrl.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.selectedItem.delete()
            self.navigationController?.popViewController(animated: true)
        }))
        present(actionCtrl, animated: true, completion: nil)
    }
    
    @IBAction func pushDoneBtn() {
        if let del = delegate {
            dismiss(animated: true, completion: {
                del.changeImage(self.selectedItem.image ?? UIImage(), data: self.selectedItem.imageData ?? Data(), isGIF: false)
            })
        }
    }
}
