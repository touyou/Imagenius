//
//  TweetViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import GoogleMobileAds
import RxSwift
import RxCocoa
import SDWebImage

protocol TweetViewControllerDelegate: class {
    func changeImage(_ image: UIImage, data: Data, isGIF: Bool)
}

final class TweetViewController: UIViewController {
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var placeHolderLabel: UILabel!
    @IBOutlet weak var tweetTextView: UITextView!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var accountImage: UIButton!
    @IBOutlet weak var tweetImageView: UIImageView!
    @IBOutlet weak var scvBackGround: UIScrollView!
    @IBOutlet weak var tweetContentView: UIView!
    @IBOutlet weak var tweetImageHeight: NSLayoutConstraint!
    @IBOutlet weak var galleryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var twBtn: UIButton!
    @IBOutlet weak var imageCollectionView: UICollectionView! {
        didSet {
            imageCollectionView.delegate = self
            imageCollectionView.dataSource = self
            imageCollectionView.backgroundColor = UIColor.white
        }
    }
    // Google Ads関連
    @IBOutlet weak var bannerView: GADBannerView!

    var MAXWORD: Int = 140
    var tweetText: String?
    var replyStr: String?
    var replyID: String?
    var tweetImage = [UIImage]()
    var accountImg: UIImage?
    var mediaIds = [String]()
    var gifFlag = true

    let saveData: UserDefaults = UserDefaults.standard
    let twitterManager = TwitterManager.shared
    let disposeBag = DisposeBag()

    // MARK: - UIViewControllerの設定
    override func viewDidLoad() {
        super.viewDidLoad()
        if saveData.object(forKey: Settings.Saveword.twitter) == nil {
            twitterManager.loginTwitter({

                self.changeAccountImage()
            })
        } else {
            
            changeAccountImage()
        }
        // レイアウト
        if replyStr != nil {
            tweetTextView.text = replyStr
        }
        searchField.placeholder = "画像を検索する"
        tweetImageHeight.constant = 0

        // RxSwiftで文字数を監視
        tweetTextView.rx.textInput.text
            .map { "\($0!.characters.count)" }
            .bind(to: countLabel.rx.text)
            .addDisposableTo(disposeBag)
        tweetTextView.rx.textInput.text
            .map {
                if $0?.characters.count == 0 {
                    self.placeHolderLabel.text = "何をつぶやく？"
                } else if ($0?.characters.count)! > self.MAXWORD {
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
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)

        cameraButton.rx.tap
            .flatMapLatest { [weak self] _ in
                return Reactive<UIImagePickerController>.createWithParent(self) { picker in
                    picker.sourceType = .camera
                    picker.allowsEditing = false
                    }
                    .flatMap { $0.rx.didFinishPickingMediaWithInfo }
                    .take(1)
            }
            .map { info in
                return info[UIImagePickerControllerOriginalImage] as? UIImage
            }
            .subscribe({ image in
                let failureHandler: ((Error) -> Void) = { error in
                    Utility.simpleAlert("Error: 画像ファイルが大きすぎるためアップロードに失敗しました。(インターネット環境を確認してください。)", presentView: self)
                }
                let im = Utility.resizeImage(image.element!!, size: CGSize(width: 1024, height: 1024))
                let data = UIImagePNGRepresentation(im)!
                self.swifter.postMedia(data, success: { status in
                    guard let media = status.object else { return }
                    if self.gifFlag && self.mediaIds.count < 4 {
                        self.tweetImageHeight.constant = 110
                        self.tweetImage.append(im)
                        self.mediaIds.append(media["media_id_string"]!.string!)
                        self.imageCollectionView.reloadData()
                    } else {
                        let alertController = UIAlertController(title: "これ以上貼り付けられません", message: "同時にアップロードできるのは画像四枚までかGIF一枚までです。", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    }
                }, failure: failureHandler)
            })
            .addDisposableTo(disposeBag)

        galleryButton.rx.tap
            .flatMapLatest { [weak self] _ in
                return Reactive<UIImagePickerController>.createWithParent(self) { picker in
                    picker.sourceType = .photoLibrary
                    picker.allowsEditing = true
                    }
                    .flatMap {
                        $0.rx.didFinishPickingMediaWithInfo
                    }
                    .take(1)
            }
            .map { info in
                return info[UIImagePickerControllerEditedImage] as? UIImage
            }
            .subscribe({ image in
                let failureHandler: ((Error) -> Void) = { error in
                    Utility.simpleAlert("Error: 画像ファイルが大きすぎるためアップロードに失敗しました。(インターネット環境を確認してください。)", presentView: self)
                }
                let im = Utility.resizeImage(image.element!!, size: CGSize(width: 1024, height: 1024))
                let data = UIImagePNGRepresentation(im)!
                self.swifter.postMedia(data, success: { status in
                    guard let media = status.object else { return }
                    if self.gifFlag && self.mediaIds.count < 4 {
                        self.tweetImageHeight.constant = 110
                        self.tweetImage.append(im)
                        self.mediaIds.append(media["media_id_string"]!.string!)
                        self.imageCollectionView.reloadData()
                    } else {
                        let alertController = UIAlertController(title: "これ以上貼り付けられません", message: "同時にアップロードできるのは画像四枚までかGIF一枚までです。", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    }
                }, failure: failureHandler)
            })
            .addDisposableTo(disposeBag)

        // Google Ads関連
        self.bannerView.adSize = kGADAdSizeSmartBannerPortrait
#if DEBUG
        self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
#else
        self.bannerView.adUnitID = "ca-app-pub-2853999389157478/5283774064"
#endif
        self.bannerView.rootViewController = self
        self.bannerView.load(GADRequest())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if accountImg == nil {
            self.accountImage.setTitle("login", for: UIControlState())
        }

        searchField.text = ""

        NotificationCenter.default.addObserver(self, selector: #selector(TweetViewController.changeOrient(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        self.view.layoutIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        self.scvBackGround.contentSize = CGSize(width: self.view.bounds.width, height: self.view.bounds.height + 200.0)
        self.scvBackGround.flashScrollIndicators()
    }

    @objc func changeOrient(_ notification: Notification) {
        self.scvBackGround.contentSize = CGSize(width: self.view.bounds.width, height: self.view.bounds.height + 200.0)
        self.scvBackGround.flashScrollIndicators()
    }

    override func didReceiveMemoryWarning() {
        let imageCache: SDImageCache = SDImageCache()
        imageCache.clearMemory()
        imageCache.clearDisk()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toImageView" {
            let navViewCtrl: UINavigationController = segue.destination as? UINavigationController ?? UINavigationController()
            let tiqavViewCtrl: TiqavImageViewController = navViewCtrl.viewControllers[0] as? TiqavImageViewController ?? TiqavImageViewController()
            tiqavViewCtrl.searchWord = searchField.text!
            tiqavViewCtrl.delegate = self
        } else if segue.identifier == "openFavoriteImage" {
            let navViewCtrl: UINavigationController = segue.destination as? UINavigationController ?? UINavigationController()
            let favViewCtrl = navViewCtrl.viewControllers[0] as? FavoriteImageViewController ?? FavoriteImageViewController()
            favViewCtrl.delegate = self
        }
    }

    // MARK: - ボタン関係
    // MARK: 投稿せずに終了
    @IBAction func cancelButton() {
        tweetText = tweetTextView.text
        if (tweetText == nil || tweetText == "") && tweetImage.count == 0 {
            self.dismiss(animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "編集内容が破棄されます。", message: "よろしいですか？", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "はい", style: .default, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    // MARK: アカウントを切り替える
    @IBAction func accountButton() {
        // アカウントの切り替え
        twitterManager.switchAccount({
            
            self.changeAccountImage()
        })
    }
    // MARK: 画像検索へ
    @IBAction func searchButton() {
        if searchField.text != "" {
            performSegue(withIdentifier: "toImageView", sender: nil)
        } else {
            Utility.simpleAlert("検索ワードを入力してください。", presentView: self)
        }
    }
    // MARK: ツイート処理
    @IBAction func tweetButton() {
        let failureHandler: ((Error) -> Void) = { error in
            self.twBtn.isEnabled = true
            Utility.simpleAlert("Error: ツイートに失敗しました。インターネット環境を確認してください。", presentView: self)
        }
        let successHandler: ((JSON) -> Void) = { status in
            self.dismiss(animated: true, completion: nil)
        }

        // ここに140字以上の処理を書く
        tweetText = tweetTextView.text
        if tweetText!.characters.count > MAXWORD {
            Utility.simpleAlert("140字を超えています。", presentView: self)
            return
        }
        if (tweetText == nil || tweetText == "") && mediaIds.count == 0 {
            Utility.simpleAlert("画像かテキストを入力してください。", presentView: self)
            return
        }

        twBtn.isEnabled = false

        if (tweetText == nil || tweetText == "") && mediaIds.count != 0 {
            swifter.postTweet(status: "", media_ids: mediaIds, success: successHandler, failure: failureHandler)
            return
        }
        if mediaIds.count == 0 {
            swifter.postTweet(status: tweetText!, inReplyToStatusID: replyID, success: successHandler, failure: failureHandler)
            return
        }
        swifter.postTweet(status: tweetText!, inReplyToStatusID: replyID, media_ids: mediaIds, success: successHandler, failure: failureHandler)
    }
    
    @IBAction func favoriteButton() {
        performSegue(withIdentifier: "openFavoriteImage", sender: nil)
    }

    // MARK: - キーボード関係の処理
    // MARK: returnでキーボードを閉じる
    func textFieldShouldReturn(_ textField: UITextField!) -> Bool {
        view.endEditing(true)
        return true
    }

    // MARK: - Utility
    // MARK: ツイートに添付する画像
    func changeImage(_ image: UIImage, data: Data, isGIF: Bool) {
        let failureHandler: ((Error) -> Void) = { error in
            Utility.simpleAlert("Error: 画像ファイルが大きすぎるためアップロードに失敗しました。(インターネット環境を確認してください。)", presentView: self)
        }
        swifter.postMedia(data, success: { status in
            guard let media = status.object else { return }
            if isGIF && self.gifFlag && self.mediaIds.count == 0 {
                // GIFが貼り付けられる場合
                self.tweetImageHeight.constant = 110
                self.tweetImage.append(image)
                self.mediaIds.append(media["media_id_string"]!.string!)
                self.gifFlag = false
                self.imageCollectionView.reloadData()
            } else if !isGIF && self.gifFlag && self.mediaIds.count < 4 {
                // 画像が貼り付けられる場合
                self.tweetImageHeight.constant = 110
                self.tweetImage.append(image)
                self.mediaIds.append(media["media_id_string"]!.string!)
                self.imageCollectionView.reloadData()
            } else {
                let alertController = UIAlertController(title: "これ以上貼り付けられません", message: "同時にアップロードできるのは画像四枚までかGIF一枚までです。", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
            }, failure: failureHandler)
    }
}

// MARK: - CollectionView
extension TweetViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaIds.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: TiqavImageViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "tweetImageCell", for: indexPath) as? TiqavImageViewCell ?? TiqavImageViewCell()
        cell.imageView.contentMode = .scaleAspectFill
        cell.imageView.image = tweetImage[indexPath.row]
        return cell
    }
    func  collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alertController = UIAlertController(title: "この画像を削除しますか？", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "はい", style: .default, handler: { _ in
            self.tweetImage.remove(at: indexPath.row)
            self.mediaIds.remove(at: indexPath.row)
            if self.mediaIds.count == 0 {
                self.tweetImageHeight.constant = 0
                self.gifFlag = true
            } else {
                self.imageCollectionView.reloadData()
            }
        }))
        alertController.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - TweetViewControllerDelegate
extension TweetViewController: TweetViewControllerDelegate {
    // MARK: アカウントの画像を切替える
    func changeAccountImage() {
        let failureHandler: ((Error) -> Void) = { error in
            Utility.simpleAlert("Error: プロフィール画像を取得できませんでした。インターネット環境を確認してください。", presentView: self)
        }
        swifter.showUser(for: .screenName(account!.username), success: {(user) -> Void in
            if let userDict = user.object {
                if let userImage = userDict["profile_image_url_https"] {
                    self.accountImg = Utility.resizeImage(UIImage(data: try! Data(contentsOf: URL(string: userImage.string!)!))!, size: CGSize(width: 50, height: 50))
                    self.accountImage.layer.cornerRadius = self.accountImage.frame.size.width * 0.5
                    self.accountImage.clipsToBounds = true
                    self.accountImage.setImage(self.accountImg, for: UIControlState())
                }
            }
            }, failure: failureHandler)
    }
}

// MARK: - RxのImagePicker設定
func dismissViewController(_ viewController: UIViewController, animated: Bool) {
    if viewController.isBeingDismissed || viewController.isBeingPresented {
        DispatchQueue.main.async {
            dismissViewController(viewController, animated: animated)
        }

        return
    }

    if viewController.presentingViewController != nil {
        viewController.dismiss(animated: animated, completion: nil)
    }
}

extension Reactive where Base: UIImagePickerController {
    static func createWithParent(_ parent: UIViewController?, animated: Bool = true, configureImagePicker: @escaping (UIImagePickerController) throws -> () = { x in }) -> Observable<UIImagePickerController> {
        return Observable.create { [weak parent] observer in
            let imagePicker = UIImagePickerController()
            let dismissDisposable = imagePicker.rx
                .didCancel
                .subscribe(onNext: { [weak imagePicker] in
                    guard let imagePicker = imagePicker else {
                        return
                    }
                    dismissViewController(imagePicker, animated: animated)
                })
            
            do {
                try configureImagePicker(imagePicker)
            }
            catch let error {
                observer.on(.error(error))
                return Disposables.create()
            }
            
            guard let parent = parent else {
                observer.on(.completed)
                return Disposables.create()
            }
            
            parent.present(imagePicker, animated: animated, completion: nil)
            observer.on(.next(imagePicker))
            
            return Disposables.create(dismissDisposable, Disposables.create {
                dismissViewController(imagePicker, animated: animated)
            })
        }
    }
}

extension Reactive where Base: UIImagePickerController {
    
    /**
     Reactive wrapper for `delegate` message.
     */
    public var didFinishPickingMediaWithInfo: Observable<[String : AnyObject]> {
        return delegate
            .methodInvoked(#selector(UIImagePickerControllerDelegate.imagePickerController(_:didFinishPickingMediaWithInfo:)))
            .map({ (a) in
                return try castOrThrow(Dictionary<String, AnyObject>.self, a[1] as AnyObject)
            })
    }
    
    /**
     Reactive wrapper for `delegate` message.
     */
    public var didCancel: Observable<()> {
        return delegate
            .methodInvoked(#selector(UIImagePickerControllerDelegate.imagePickerControllerDidCancel(_:)))
            .map {_ in () }
    }
    
}

fileprivate func castOrThrow<T>(_ resultType: T.Type, _ object: AnyObject) throws -> T {
    guard let returnValue = object as? T else {
        throw RxCocoaError.castingError(object: object, targetType: resultType)
    }
    
    return returnValue
}
