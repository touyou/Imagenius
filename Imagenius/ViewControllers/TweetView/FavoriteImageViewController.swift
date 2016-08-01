//
//  FavoriteImageViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/08/01.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

final class FavoriteImageViewController: UIViewController {
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    var collectionData = [FavoriteImage]()
    var selectedItem: FavoriteImage!
    var delegate: TweetViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageCollectionView.dataSource = self
        imageCollectionView.delegate = self
        imageCollectionView.emptyDataSetSource = self
        imageCollectionView.emptyDataSetDelegate = self
        imageCollectionView.backgroundColor = UIColor.whiteColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        collectionData = FavoriteImage.loadAll()
        imageCollectionView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPreview" {
            let viewCtrl = segue.destinationViewController as? FavoriteResultViewController ?? FavoriteResultViewController()
            viewCtrl.delegate = self.delegate
            viewCtrl.selectedItem = self.selectedItem
        }
    }
    
    @IBAction func cancelButton() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func galleryBtn() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
}


extension FavoriteImageViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: FavoriteImageViewCell = imageCollectionView.dequeueReusableCellWithReuseIdentifier("fImageCell", forIndexPath: indexPath) as? FavoriteImageViewCell ?? FavoriteImageViewCell()
        
        cell.imageView.contentMode = .ScaleAspectFill
        cell.imageView.image = collectionData[indexPath.row].image
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedItem = collectionData[indexPath.row]
        performSegueWithIdentifier("showPreview", sender: nil)
    }
}

extension FavoriteImageViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "お気に入りの画像を保存してください。"
        let font = UIFont.systemFontOfSize(20)
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
    }
}

extension FavoriteImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let favoriteImage = FavoriteImage.create()
            favoriteImage.image = pickedImage
            favoriteImage.save()
        }
        
        collectionData = FavoriteImage.loadAll()
        imageCollectionView.reloadData()
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}
