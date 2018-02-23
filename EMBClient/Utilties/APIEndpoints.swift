//
//  APIEndpoints.swift
//  EMBClient
//
//  Created by Chen Zerui on 12/1/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//

import Foundation

struct APIEndpoints {
    static let loginURL = URL(string: "https://iemb.hci.edu.sg/home/login")!
    static let boardBaseURL = URL(string: "https://iemb.hci.edu.sg/Board/Detail")!
    
    static func boardURL(forId id: Int)-> URL {
        return boardBaseURL.appendingPathComponent(String(id))
    }
    
    static func postURL(forId id: Int, boardId: Int)-> URL {
        return URL(string: "https://iemb.hci.edu.sg/Board/content/\(id)?board=\(boardId)")!
    }
    
    static let responseURL = URL(string: "https://iemb.hci.edu.sg/board/ProcessResponse")!
    
}
