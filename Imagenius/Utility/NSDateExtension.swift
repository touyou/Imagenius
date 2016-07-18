//
//  NSDateExtension.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/04/10.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
extension NSDate {
    func yearsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Year, fromDate: date, toDate: self, options: []).year
    }
    func monthsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Month, fromDate: date, toDate: self, options: []).month
    }
    func weeksFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.WeekOfYear, fromDate: date, toDate: self, options: []).weekOfYear
    }
    func daysFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Day, fromDate: date, toDate: self, options: []).day
    }
    func hoursFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Hour, fromDate: date, toDate: self, options: []).hour
    }
    func minutesFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Minute, fromDate: date, toDate: self, options: []).minute
    }
    func secondsFrom(date: NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Second, fromDate: date, toDate: self, options: []).second
    }
    func offsetFrom(date: NSDate) -> String {
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

func dateTimeFromTwitterDate(date: String) -> NSDate {
    let inputDateFormatter = NSDateFormatter()
    let locale = NSLocale(localeIdentifier: "en_US")
    inputDateFormatter.locale = locale
    inputDateFormatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
    let resDate = inputDateFormatter.dateFromString(date)
    return resDate ?? NSDate()
}
