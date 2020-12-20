//
//  TimeUtils.swift
//  Runner
//
//  Created by xuqi zhong on 2020/12/21.
//

import Foundation

class TimeUtils {
    class func getMillisecondsSince1970() -> Int64 {
        return Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
    }
}
