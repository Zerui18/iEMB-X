//
//  String+HTMLUnEscape.swift
//  EMBClient
//
//  Created by Chen Zerui on 26/1/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//

import Foundation


extension String {
    var removingHTMLEncoding: String {
        let htmlDecoded = try? NSAttributedString(data: data(using: .utf8)!, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        return htmlDecoded?.string ?? self
    }
}
