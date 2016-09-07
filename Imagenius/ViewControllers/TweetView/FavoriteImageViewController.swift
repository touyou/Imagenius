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
        imageCollectionView.backgroundColor = UIColor.white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        collectionData = FavoriteImage.loadAll()
        imageCollectionView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPreview" {
            let viewCtrl = segue.destination as? FavoriteResultViewController ?? FavoriteResultViewController()
            viewCtrl.delegate = self.delegate
            viewCtrl.selectedItem = self.selectedItem
        }
    }
    
    @IBAction func cancelButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func galleryBtn() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            present(imagePicker, animated: true, completion: nil)
        }
    }
}


extension FavoriteImageViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: FavoriteImageViewCell = imageCollectionView.dequeueReusableCell(withReuseIdentifier: "fImageCell", for: indexPath) as? FavoriteImageViewCell ?? FavoriteImageViewCell()
        
        cell.imageView.contentMode = .scaleAspectFill
        cell.imageView.image = collectionData[(indexPath as NSIndexPath).row].image
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedItem = collectionData[(indexPath as NSIndexPath).row]
        performSegue(withIdentifier: "showPreview", sender: nil)
    }
}

extension FavoriteImageViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "お気に入りの画像を保存してください。"
        let font = UIFont.systemFont(ofSize: 20)
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
    }
}

extension FavoriteImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let favoriteImage = FavoriteImage.create()
            favoriteImage.image = pickedImage
            favoriteImage.save()
        }
        
        collectionData = FavoriteImage.loadAll()
        imageCollectionView.reloadData()
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
