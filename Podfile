# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
# Uncomment this line if you're using Swift
use_frameworks!

target 'Imagenius' do
    pod 'DZNEmptyDataSet'
    pod 'SWTableViewCell', '~> 0.3.7'
    pod 'TTTAttributedLabel'
    pod 'Google-Mobile-Ads-SDK', '~> 7.0'
    pod 'KTCenterFlowLayout'
    pod 'RegExCategories', '~> 1.0'
    pod 'SDWebImage'
    pod 'Alamofire', '~> 4.0'
    pod 'SwiftyJSON', :git => 'https://github.com/IBM-Swift/SwiftyJSON.git'
    pod 'Realm'
    pod 'RealmSwift'
    pod 'RxSwift', '~> 3.0.0.alpha.1'
    pod 'RxCocoa', '~> 3.0.0.alpha.1'
end

target 'ImageniusTests' do
    pod 'RxBlocking', '~> 3.0.0.alpha.1'
    pod 'RxTests', '~> 3.0.0.alpha.1'
end

target 'ImageniusUITests' do

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end

