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
    pod 'Alamofire', :git => 'https://github.com/Alamofire/Alamofire.git', :branch => 'swift3'
    pod 'SwiftyJSON', :git => 'https://github.com/IBM-Swift/SwiftyJSON.git'
    pod 'RealmSwift', git: 'git@github.com:realm/realm-cocoa.git', branch: 'master', :submodules => true
    pod 'RxSwift', :git => 'https://github.com/ReactiveX/RxSwift.git', :branch => 'develop'
    pod 'RxCocoa', :git => 'https://github.com/ReactiveX/RxSwift.git', :branch => 'develop'
    #    pod 'RxBlocking'
    #    pod 'RxTests'
end

target 'ImageniusTests' do

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

