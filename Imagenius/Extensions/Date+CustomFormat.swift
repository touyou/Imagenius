//
//  NSDateExtension.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/04/10.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
extension Date {
    func yearsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.year, from: date, to: self, options: []).year!
    }
    func monthsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.month, from: date, to: self, options: []).month!
    }
    func weeksFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.weekOfYear, from: date, to: self, options: []).weekOfYear!
    }
    func daysFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.day, from: date, to: self, options: []).day!
    }
    func hoursFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.hour, from: date, to: self, options: []).hour!
    }
    func minutesFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.minute, from: date, to: self, options: []).minute!
    }
    func secondsFrom(_ date: Date) -> Int {
        return (Calendar.current as NSCalendar).components(NSCalendar.Unit.second, from: date, to: self, options: []).second!
    }
    func offsetFrom(_ date: Date) -> String {
        if yearsFrom(date)   > 0 { return "\(yearsFrom(date))年前"   }
        if monthsFrom(date)  > 0 { return "\(monthsFrom(date))ヶ月前"  }
        if weeksFrom(date)   > 0 { return "\(weeksFrom(date))週間前"   }
        if daysFrom(date)    > 0 { return "\(daysFrom(date))日前"    }
        if hoursFrom(date)   > 0 { return "\(hoursFrom(date))時間前"   }
        if minutesFrom(date) > 0 { return "\(minutesFrom(date))分前" }
        if secondsFrom(date) > 0 { return "\(secondsFrom(date))秒前" }
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
