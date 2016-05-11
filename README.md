# Imagenius

面白画像でスマートなTwitterライフを
![imagenius_logo](extra/imagenius-logo_new.png)

## ファイル説明
- Utility...いろんなところで使う関数をまとめたクラス
    - TwitterUtil.swift ... Twitterのログインなどをする関数
    - Utility.swift ... 簡単なアラートを出す関数、画像の切り抜きなど
    - NSDateExtension.swift ... ある日付と現在の相対時間の表示をする拡張やTwitterの時刻表示をNSDateになおす関数など
- Constant...定数を扱う
    - Settings.swift ... 色やNSUserDefaults用の定数
- ViewModels...TableViewやCollectionViewのDataSourceなど
    - MainView...そのうちのタイムライン画面などに関するもの
        - MainViewModel.swift ... タイムライン画面のDataSource
        - UserViewModel.swift ... ユーザータイムラインのDataSource
        - TweetDetailViewModel.swift ... Tweet詳細画面のDataSource
    - TweetView...そのうちのツイート画面などに関するもの
        - TiqavImageViewModel.swift ... 画像検索結果一覧のDataSource
- Models...MVVMモデルのModelに相当するもの
    - MainView...一応あるけど中のファイルも特に意味はない
    - TweetView...ツイート画面などに関するもの
        - TiqavImageModel.swift ... APIのリクエストをなげている
- ViewControllers...その名の通り
    - InfoView...初回起動時などの説明画面
        - InfoContainerViewController.swift ... 説明画面の一番の外枠
        - InfoPageViewController.swift ... PageViewになっている部分の処理
        - InfoViewController.swift ... PageViewに入ってる一つ一つの画面
    - SettingView...設定画面
        - SettingTableViewController.swift ... そのまんま
    - WebView...その名の通り
        - WebViewController.swift ... 同上
    - MainView...ツイートを閲覧する部分
        - GIFViewController.swift ... GIFのプレビュー画面。TwitterでGIFはMP4になっているので実質動画のプレビュー
        - ImagePreViewController.swift ... 画像のプレビュー画面。PageViewControllerを使用
        - MainViewController.swift ... ホームとリプライのタイムライン画面の大枠。これを継承してホームタイムラインとリプライタイムラインのクラスを作る
        - PreViewController.swift ... 画像のプレビューの一枚一枚の画面
        - ReplyViewController.swift ... リプライ画面。継承してるのでロードの中身を書くだけ
        - TimeLineViewController.swift ... ホームタイムライン画面。同上。
        - UserViewController.swift ... ユーザータイムライン画面。これは継承しておらず大体書いてある
        - TweetDetailViewController.swift ... ツイート詳細画面。同上。
    - TweetView...つぶやき関連の画面
        - TiqavImageViewController.swift ... 画像検索結果画面。CollectionViewで。
        - ResultViewController.swift ... 選択した画像のプレビュー
        - TweetViewController.swift ... つぶやき画面。RxSwiftというライブラリを活用して文字数をリアルタイムにカウントする。
- Views...表示に関するもの
    - SettingView...設定画面に関するもの
        - SettingBannerCell.swift ... 設定画面に表示する広告のセル
    - MainView
        - AVPlayerView.swift ... 動画再生画面
        - TweetVarViewCell.swift ... 一般的なタイムライン画面のセル
        - TweetByDictViewCell.swift ... ユーザータイムライン専用
    - TweetView
        - TiqavImageViewCell.swift ... 画像検索結果のセル

## 機能  
- TL、リプ通知の表示
- いいね、リツイート、リプライボタン
- ツイート
- 面白画像の検索とはりつけ
 
いいね、リツイート、リプライやツイートの詳細、ツイートしたユーザープロフィールの情報へはスワイプしてあらわれるボタンをタップすることでできます。

## 使用ライブラリ
- Swifter
- Alamofire
- SwiftyJSON
- Google-Mobile-Ads-SDK
- DZNEmptyDataset
- SWTableViewCell
- KTCenterFlowLayout
- TTTAttributedLabel

## リンク
- [初めてのオリジナルiPhoneアプリをつくるまで](http://qiita.com/touyoubuntu/items/ea7b42e00050083bd2ff)
