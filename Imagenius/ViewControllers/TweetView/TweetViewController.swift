//
//  TweetViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS
import Accounts
import GoogleMobileAds
import RxSwift
import RxCocoa
import SDWebImage
import KTCenterFlowLayout

protocol TweetViewControllerDelegate {
    func changeImage(image: UIImage, data: NSData, isGIF: Bool)
}

class TweetViewController: UIViewController, TweetViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var placeHolderLabel: UILabel!
    @IBOutlet var tweetTextView: UITextView!
    @IBOutlet var searchField: UITextField!
    @IBOutlet var accountImage: UIButton!
    @IBOutlet var tweetImageView: UIImageView!
    @IBOutlet var scvBackGround: UIScrollView!
    @IBOutlet var tweetContentView: UIView!
    @IBOutlet var tweetImageHeight: NSLayoutConstraint!
    @IBOutlet var galleryButton: UIButton!
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var twBtn: UIButton!
    @IBOutlet var imageCollectionView: UICollectionView!
    // Google Ads関連
    @IBOutlet var bannerView: GADBannerView!
    
    var MAX_WORD: Int = 140
    var tweetText: String?
    var replyStr: String?
    var replyID: String?
    var tweetImage = [UIImage]()
    var accountImg: UIImage?
    var swifter:Swifter!
    var account: ACAccount?
    var accounts = [ACAccount]()
    var media_ids = [String]()
    var gifFlag = true
    
    let accountStore = ACAccountStore()
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    let disposeBag = DisposeBag()
    
    // UIViewControllerの設定----------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        if saveData.objectForKey(Settings.Saveword.twitter) == nil {
            TwitterUtil.loginTwitter(self, success: { (ac) -> () in
                self.account = ac
                self.swifter = Swifter(account: self.account!)
                self.changeAccountImage()
            })
        } else {
            let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
                if granted {
                    self.accounts = self.accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                    if self.accounts.count != 0 {
                        self.account = self.accounts[self.saveData.objectForKey(Settings.Saveword.twitter) as! Int]
                        self.swifter = Swifter(account: self.account!)
                        self.changeAccountImage()
                    }
                }
            }
        }
        // レイアウト
        if replyStr != nil {
            tweetTextView.text = replyStr
        }
        searchField.placeholder = "画像を検索する"
        tweetImageHeight.constant = 0
        
        let flowLayout = KTCenterFlowLayout()
        flowLayout.scrollDirection = .Horizontal
        flowLayout.minimumInteritemSpacing = 10
        flowLayout.minimumLineSpacing = 10
        flowLayout.itemSize = CGSizeMake(110, 110)
        imageCollectionView.collectionViewLayout = flowLayout
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
        imageCollectionView.backgroundColor = UIColor.whiteColor()
        
        // RxSwiftで文字数を監視
        tweetTextView.rx_text
            .map { "\($0.characters.count)" }
            .bindTo(countLabel.rx_text)
            .addDisposableTo(disposeBag)
        tweetTextView.rx_text
            .map {
                if $0.characters.count == 0 {
                    self.placeHolderLabel.text = "何をつぶやく？"
                } else if $0.characters.count > self.MAX_WORD {
                    self.placeHolderLabel.text = nil
                    self.countLabel.textColor = Settings.Colors.mainColor
                } else {
                    self.placeHolderLabel.text = nil
                    self.countLabel.textColor = Settings.Colors.selectedColor
                }
            }
            .subscribe {}
            .addDisposableTo(disposeBag)
        
        // カメラのとか
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(.Camera)
        
        cameraButton.rx_tap
            .flatMapLatest { [weak self] _ in
                return UIImagePickerController.rx_createWithParent(self) { picker in
                    picker.sourceType = .Camera
                    picker.allowsEditing = false
                    }
                    .flatMap { $0.rx_didFinishPickingMediaWithInfo }
                    .take(1)
            }
            .map { info in
                return info[UIImagePickerControllerOriginalImage] as? UIImage
            }
            .subscribe({ image in
                let failureHandler: ((NSError) -> Void) = { error in
                    Utility.simpleAlert("Error: 画像ファイルが大きすぎるためアップロードに失敗しました。(インターネット環境を確認してください。)", presentView: self)
                }
                let im = image.element!
                let data = UIImagePNGRepresentation(im!)!
                self.swifter.postMedia(data, success: { status in
                    guard let media = status else { return }
                    if self.gifFlag && self.media_ids.count < 4 {
                        self.tweetImageHeight.constant = 110
                        self.tweetImage.append(im!)
                        self.media_ids.append(media["media_id_string"]!.string!)
                        self.imageCollectionView.reloadData()
                    } else {
                        let alertController = UIAlertController(title: "これ以上貼り付けられません", message: "同時にアップロードできるのは画像四枚までかGIF一枚までです。", preferredStyle: .Alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                        self.presentViewController(alertController, animated: true, completion: nil)
                    }
                }, failure: failureHandler)
            })
            .addDisposableTo(disposeBag)
        
        galleryButton.rx_tap
            .flatMapLatest { [weak self] _ in
                return UIImagePickerController.rx_createWithParent(self) { picker in
                    picker.sourceType = .PhotoLibrary
                    picker.allowsEditing = false
                    }
                    .flatMap {
                        $0.rx_didFinishPickingMediaWithInfo
                    }
                    .take(1)
            }
            .map { info in
                return info[UIImagePickerControllerOriginalImage] as? UIImage
            }
            .subscribe({ image in
                let failureHandler: ((NSError) -> Void) = { error in
                    Utility.simpleAlert("Error: 画像ファイルが大きすぎるためアップロードに失敗しました。(インターネット環境を確認してください。)", presentView: self)
                }
                let im = image.element!
                let data = UIImagePNGRepresentation(im!)!
                self.swifter.postMedia(data, success: { status in
                    guard let media = status else { return }
                    if self.gifFlag && self.media_ids.count < 4 {
                        self.tweetImageHeight.constant = 110
                        self.tweetImage.append(im!)
                        self.media_ids.append(media["media_id_string"]!.string!)
                        self.imageCollectionView.reloadData()
                    } else {
                        let alertController = UIAlertController(title: "これ以上貼り付けられません", message: "同時にアップロードできるのは画像四枚までかGIF一枚までです。", preferredStyle: .Alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                        self.presentViewController(alertController, animated: true, completion: nil)
                    }
                }, failure: failureHandler)
            })
            .addDisposableTo(disposeBag)
        
        // Google Ads関連
        self.bannerView.adSize = kGADAdSizeSmartBannerPortrait
        // for test
        // self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        // for sale
        self.bannerView.adUnitID = "ca-app-pub-2853999389157478/5283774064"
        self.bannerView.rootViewController = self
        self.bannerView.loadRequest(GADRequest())
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if accountImg == nil {
            self.accountImage.setTitle("login", forState: .Normal)
        }
        
        searchField.text = ""
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TweetViewController.changeOrient(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        self.view.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        self.scvBackGround.contentSize = CGSizeMake(self.view.bounds.width, self.view.bounds.height + 200.0)
        self.scvBackGround.flashScrollIndicators()
    }
    
    func changeOrient(notification: NSNotification) {
        self.scvBackGround.contentSize = CGSizeMake(self.view.bounds.width, self.view.bounds.height + 200.0)
        self.scvBackGround.flashScrollIndicators()
    }
    
    override func didReceiveMemoryWarning() {
        let imageCache: SDImageCache = SDImageCache()
        imageCache.clearMemory()
        imageCache.clearDisk()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toImageView" {
            let navViewCtrl: UINavigationController = segue.destinationViewController as! UINavigationController
            let tiqavViewCtrl: TiqavImageViewController = navViewCtrl.viewControllers[0] as! TiqavImageViewController
            tiqavViewCtrl.searchWord = searchField.text!
            tiqavViewCtrl.delegate = self
        }
    }
    
    // ボタン関係-----------------------------------------------------------------
    // 投稿せずに終了
    @IBAction func cancelButton() {
        tweetText = tweetTextView.text
        if (tweetText == nil || tweetText == "") && tweetImage.count == 0 {
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "編集内容が破棄されます。", message: "よろしいですか？", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "はい", style: .Default, handler: {
                action in
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "いいえ", style: .Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    // アカウントを切り替える
    @IBAction func accountButton() {
        // アカウントの切り替え
        TwitterUtil.loginTwitter(self, success: { (ac) -> () in
            self.account = ac
            self.swifter = Swifter(account: self.account!)
            self.changeAccountImage()
        })
    }
    // 画像検索へ
    @IBAction func searchButton() {
        if searchField.text != "" {
            performSegueWithIdentifier("toImageView", sender: nil)
        } else {
            Utility.simpleAlert("検索ワードを入力してください。", presentView: self)
        }
    }
    // ツイート処理
    @IBAction func tweetButton() {
        let failureHandler: ((NSError) -> Void) = { error in
            self.twBtn.enabled = true
            Utility.simpleAlert("Error: ツイートに失敗しました。インターネット環境を確認してください。", presentView: self)
        }
        let successHandler: ((Dictionary<String, JSONValue>?) -> Void) = { status in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        // ここに140字以上の処理を書く
        tweetText = tweetTextView.text
        if (tweetText!.characters.count > MAX_WORD) {
            Utility.simpleAlert("140字を超えています。", presentView: self)
            return
        }
        if (tweetText == nil || tweetText == "") && media_ids.count == 0 {
            Utility.simpleAlert("画像かテキストを入力してください。", presentView: self)
            return
        }
        
        twBtn.enabled = false
        
        if (tweetText == nil || tweetText == "") && media_ids.count != 0 {
            swifter.postStatusUpdate("", media_ids: media_ids, success: successHandler, failure: failureHandler)
            return
        }
        if media_ids.count == 0 {
            swifter.postStatusUpdate(tweetText!, inReplyToStatusID: replyID, success: successHandler, failure: failureHandler)
            return
        }
        swifter.postStatusUpdate(tweetText!, media_ids: media_ids, inReplyToStatusID: replyID, success: successHandler, failure: failureHandler)
    }
    
    // MARK: - CollectionView
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return media_ids.count
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: TiqavImageViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("tweetImageCell", forIndexPath: indexPath) as! TiqavImageViewCell
        cell.imageView.image = tweetImage[indexPath.row]
        return cell
    }
    func  collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let alertController = UIAlertController(title: "この画像を削除しますか？", message: nil, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "はい", style: .Default, handler: {
            action in
            self.tweetImage.removeAtIndex(indexPath.row)
            self.media_ids.removeAtIndex(indexPath.row)
            if self.media_ids.count == 0 {
                self.tweetImageHeight.constant = 0
                self.gifFlag = true
            } else {
                self.imageCollectionView.reloadData()
            }
        }))
        alertController.addAction(UIAlertAction(title: "いいえ", style: .Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // キーボード関係の処理---------------------------------------------------------
    // returnでキーボードを閉じる
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        view.endEditing(true)
        return true
    }
    
    // Utility------------------------------------------------------------------
    // アカウントの画像を切替える
    func changeAccountImage() {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert("Error: プロフィール画像を取得できませんでした。インターネット環境を確認してください。", presentView: self)
        }
        swifter.getUsersShowWithScreenName(account!.username, success: {(user) -> Void in
            if let userDict = user {
                if let userImage = userDict["profile_image_url_https"] {
                    self.accountImg = Utility.resizeImage(UIImage(data: NSData(contentsOfURL: NSURL(string: userImage.string!)!)!)!, size: CGSize(width: 50, height: 50))
                    self.accountImage.layer.cornerRadius = self.accountImage.frame.size.width * 0.5
                    self.accountImage.clipsToBounds = true
                    self.accountImage.setImage(self.accountImg, forState: .Normal)
                }
            }
        }, failure: failureHandler)
    }
    // ツイートに添付する画像
    func changeImage(image: UIImage, data: NSData, isGIF: Bool) {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert("Error: 画像ファイルが大きすぎるためアップロードに失敗しました。(インターネット環境を確認してください。)", presentView: self)
        }
        swifter.postMedia(data, success: { status in
            guard let media = status else { return }
            if isGIF && self.gifFlag && self.media_ids.count == 0 {
                // GIFが貼り付けられる場合
                self.tweetImageHeight.constant = 110
                self.tweetImage.append(image)
                self.media_ids.append(media["media_id_string"]!.string!)
                self.gifFlag = false
                self.imageCollectionView.reloadData()
            } else if !isGIF && self.gifFlag && self.media_ids.count < 4 {
                // 画像が貼り付けられる場合
                self.tweetImageHeight.constant = 110
                self.tweetImage.append(image)
                self.media_ids.append(media["media_id_string"]!.string!)
                self.imageCollectionView.reloadData()
            } else {
                let alertController = UIAlertController(title: "これ以上貼り付けられません", message: "同時にアップロードできるのは画像四枚までかGIF一枚までです。", preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            }, failure: failureHandler)
    }
}

func dismissViewController(viewController: UIViewController, animated: Bool) {
    if viewController.isBeingDismissed() || viewController.isBeingPresented() {
        dispatch_async(dispatch_get_main_queue()) {
            dismissViewController(viewController, animated: animated)
        }
        
        return
    }
    
    if viewController.presentingViewController != nil {
        viewController.dismissViewControllerAnimated(animated, completion: nil)
    }
}

extension UIImagePickerController {
    static func rx_createWithParent(parent: UIViewController?, animated: Bool = true, configureImagePicker: (UIImagePickerController) throws -> () = { x in }) -> Observable<UIImagePickerController> {
        return Observable.create { [weak parent] observer in
            let imagePicker = UIImagePickerController()
            let dismissDisposable = imagePicker
                .rx_didCancel
                .subscribeNext({ [weak imagePicker] in
                    guard let imagePicker = imagePicker else {
                        return
                    }
                    dismissViewController(imagePicker, animated: animated)
                    })
            
            do {
                try configureImagePicker(imagePicker)
            }
            catch let error {
                observer.on(.Error(error))
                return NopDisposable.instance
            }
            
            guard let parent = parent else {
                observer.on(.Completed)
                return NopDisposable.instance
            }
            
            parent.presentViewController(imagePicker, animated: animated, completion: nil)
            observer.on(.Next(imagePicker))
            
            return CompositeDisposable(dismissDisposable, AnonymousDisposable {
                dismissViewController(imagePicker, animated: animated)
                })
        }
    }
}
