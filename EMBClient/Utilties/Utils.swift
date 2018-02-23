//
//  Utils.swift
//  EMBClient
//
//  Created by Chen Zerui on 12/1/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//

import Foundation

let cachedFilesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Files")

infix operator ~
func ~(_ lhs: String, _ rhs: NSRegularExpression)-> NSTextCheckingResult? {
    return rhs.firstMatch(in: lhs, options: [], range: NSRange(location: 0, length: lhs.count))
}
