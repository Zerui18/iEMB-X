//
//  String+HTMLUnEscape.swift
//  EMBClient
//
//  Created by Chen Zerui on 26/1/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//

import Foundation

let htmlEscaped = ["&amp;"     :   "&",
                   "&gt;"      :   ">",
                   "&lt;"      :   "<",
                   "&quot;"    :   "\"",
                   "&#39;"     :   "'",
                   "&#160;"    :   " "]

extension String {
    var removingHTMLEncoding: String {
        var result = self
        for (enc, ori) in htmlEscaped {
            result = result.replacingOccurrences(of: enc, with: ori)
        }
        return result
    }
}
