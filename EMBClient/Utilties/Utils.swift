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

extension URLRequest {
    
    /// Returns a copy of the request, with the appropriate modifications for iEMB.
    var iembModified: URLRequest {
        var copy = self
        copy.setValue("https://iemb.hci.edu.sg/", forHTTPHeaderField: "Referer")
        return copy
    }
    
    /// Returns a copy of the request, with the headers filled with auth cookies. Returns nil if auth parameters haven't been saved.
    var signed: URLRequest? {
        guard let id = EMBUser.shared.sessionId, let auth = EMBUser.shared.authToken else {
            return nil
        }
        var mutable = self
        mutable.setValue("ASP.NET_SessionId=\(id); AuthenticationToken=\(auth)", forHTTPHeaderField: "Cookie")
        return mutable
    }

    
}

/// URLSession(Task)Delagate that prevents automatic HTML redirect.
class NoRedirectDelegate : NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

/// Helper function that retrieves the value of a cookies with the given name from the shared HTTPCookiesStorage.
func cookie(named name: String)-> String? {
    return HTTPCookieStorage.shared.cookies?.first(where: { $0.name == name })?.value
}
