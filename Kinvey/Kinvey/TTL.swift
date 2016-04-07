//
//  CachedStoreExpiration.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-13.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public enum TimeUnit {
    case Second
    case Minute
    case Hour
    case Day
    case Month
    case Year
}

public typealias TTL = (Int, TimeUnit)

extension Int {
    
    public var second   : NSDate { get { return date(.Second) } }
    public var minute   : NSDate { get { return date(.Minute) } }
    public var hour     : NSDate { get { return date(.Hour) } }
    public var day      : NSDate { get { return date(.Day) } }
    public var month    : NSDate { get { return date(.Month) } }
    public var year     : NSDate { get { return date(.Year) } }
    
    internal func date(timeUnit: TimeUnit, calendar: NSCalendar = NSCalendar.currentCalendar()) -> NSDate {
        let dateComponents = NSDateComponents()
        switch timeUnit {
        case .Second:
            dateComponents.day = -self
        case .Minute:
            dateComponents.minute = -self
        case .Hour:
            dateComponents.hour = -self
        case .Day:
            dateComponents.day = -self
        case .Month:
            dateComponents.month = -self
        case .Year:
            dateComponents.year = -self
        }
        let newDate = calendar.dateByAddingComponents(dateComponents, toDate: NSDate(), options: [])
        return newDate!
    }
    
}
