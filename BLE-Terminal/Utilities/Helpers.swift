//
//  Helpers.swift
//  BLE Terminal
//
//  Created by Ashwin Gattani on 08/09/25.
//

import Foundation

// MARK: - Helpers
func secondsToMinSec(_ seconds: Int) -> (Int, Int) {
    return (seconds / 60, seconds % 60)
}

enum Weekdays: Int, CaseIterable, Identifiable, Encodable, Decodable {
    case monday = 1
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "U"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "H"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
}

func getCalendarComponents(date: Date) -> DateComponents {
    let userCalendar = Calendar.current

    // choose which date and time components are needed
    let requestedComponents: Set<Calendar.Component> = [
        .year,
        .month,
        .day,
        .hour,
        .minute,
        .second,
        .weekday
    ]

    // get the components
    return userCalendar.dateComponents(requestedComponents, from: date)
}


enum commands: String {
    case run = "$Q#"
    
    static func setTime(seconds: Int) -> String {
        return "$C\(seconds)#"
    }
    
    static func calibarateTime() -> String {
        let dateTimeComponents = getCalendarComponents(date: Date())

        return "$R,\(dateTimeComponents.day!),\(dateTimeComponents.month!),\((dateTimeComponents.year ?? 20) % 100),\(Weekdays(rawValue: dateTimeComponents.weekday ?? 1)!.shortName),\(dateTimeComponents.hour!),\(dateTimeComponents.minute!),\(dateTimeComponents.second!)#"
    }
    
    static func setSchedule(weekday: Int, hour: Int, minute: Int, seconds: Int) -> String {
        return "$S,\(Weekdays(rawValue: weekday)!.shortName),\(hour):\(minute),\(seconds)#"
    }
    
    static func deleteSchedule(weekday: Int, hour: Int, minute: Int, seconds: Int) -> String {
        return "$D,\(Weekdays(rawValue: weekday)!.shortName),\(hour):\(minute),\(seconds)#"
    }
}


//MARK: Date Extension
extension Date {
    
    /// Create a new date using the current year, month, day, and hour — but custom minutes and seconds.
    static func with(hour: Int, minutes: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        components.hour = hour
        components.minute = minutes
        
        return calendar.date(from: components)!
    }
    
    /// Returns a new date by setting minutes and seconds on an existing date.
    func setting(minutes: Int, seconds: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        components.minute = minutes
        components.second = seconds
        return calendar.date(from: components)
    }
    
    /// Returns a new date by adding minutes and seconds to the current date.
    func adding(minutes: Int, seconds: Int) -> Date? {
        let totalSeconds = minutes * 60 + seconds
        return Calendar.current.date(byAdding: .second, value: totalSeconds, to: self)
    }
}
