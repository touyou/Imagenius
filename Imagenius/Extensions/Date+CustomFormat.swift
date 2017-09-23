//
//  NSDateExtension.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/04/10.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
extension Date {

    func offsetFrom() -> String {
        
        if Calendar.current.component(.year, from: self) > 0 {
            
            return "\(Calendar.current.component(.year, from: self))年前"
        }
        if Calendar.current.component(.month, from: self) > 0 {
            
            return "\(Calendar.current.component(.month, from: self))ヶ月前"
        }
        if Calendar.current.component(.weekday, from: self) > 0 {
            
            return "\(Calendar.current.component(.weekday, from: self))週間前"
        }
        if Calendar.current.component(.day, from: self) > 0 {
            
            return "\(Calendar.current.component(.day, from: self))日前"
        }
        if Calendar.current.component(.hour, from: self) > 0 {
            
            return "\(Calendar.current.component(.hour, from: self))時間前"
        }
        if Calendar.current.component(.minute, from: self) > 0 {
            
            return "\(Calendar.current.component(.minute, from: self))分前"
        }
        if Calendar.current.component(.second, from: self) > 0 {
            
            return "\(Calendar.current.component(.second, from: self))秒前"
        }
        return ""
    }
}

func dateTimeFromTwitterDate(_ date: String) -> Date {
    let inputDateFormatter = DateFormatter()
    let locale = Locale(identifier: "en_US")
    inputDateFormatter.locale = locale
    inputDateFormatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
    let resDate = inputDateFormatter.date(from: date)
    return resDate ?? Date()
}
