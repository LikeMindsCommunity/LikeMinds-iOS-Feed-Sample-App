Pod::Spec.new do |spec|

  spec.name         = "FeedSX"
  spec.version      = "1.6.0"
  spec.summary      = "Masterpiece in Making"
  
  spec.description  = <<-DESC
  MasterPiece in Making, integrate Feed in your iOS Application in minutes!
                        DESC

  spec.homepage     = "https://likeminds.community/"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "pushpendrasingh" => "pushpendra.singh@likeminds.community" }

  spec.platform = :ios
  spec.ios.deployment_target = '13.0'
  spec.swift_version = '5.0'

  spec.source       = { :git => "https://github.com/LikeMindsCommunity/LikeMinds-iOS-Feed-Sample-App.git", :tag => "v#{spec.version}" }

  spec.source_files  = "**/*.{swift}"

  spec.dependency "Kingfisher"
  spec.dependency "AWSCore"
  spec.dependency "AWSCognito"
  spec.dependency "AWSS3"
  spec.dependency "BSImagePicker"
  spec.dependency "FirebaseCore"
  spec.dependency "FirebaseMessaging"
  spec.dependency "IQKeyboardManagerSwift"
  spec.dependency "LikeMindsFeed"

end
