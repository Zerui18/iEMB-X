//
//  EMBUser.swift
//  EMBClient
//
//  Created by Chen Zerui on 12/1/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//

import Foundation

public class EMBUser {
    
    public static let shared = EMBUser()
    
    let userDefaults = UserDefaults.standard
    
    var credentials: (userId: String, password: String)? {
        get {
            if let u = userDefaults.string(forKey: "u"), let p = userDefaults.string(forKey: "p") {
                return (userId: u, password: p)
            }
            return nil
        }
        set {
            if let newCredentials = newValue {
                userDefaults.setValue(newCredentials.userId, forKey: "u")
                userDefaults.setValue(newCredentials.password, forKey: "p")
            }
            else {
                userDefaults.removeObject(forKey: "u")
                userDefaults.removeObject(forKey: "p")
            }
        }
    }
    
    fileprivate var sessionId: String? {
        get {
            return userDefaults.string(forKey: "sessId")
        }
        set {
            userDefaults.set(newValue, forKey: "sessId")
        }
    }
    
    public func hasSavedCredentials()-> Bool {
        return credentials != nil
    }
    
    public func isAuthenticated()-> Bool {
        return sessionId != nil
    }
    
    public func saveSessionId()-> Bool {
        guard let cookie = HTTPCookieStorage.shared.cookies?.first(where: {$0.name=="ASP.NET_SessionId"}) else {
            return false
        }
        sessionId = cookie.value
        return true
    }
    
    func removeSessionId() {
        if let cookies = HTTPCookieStorage.shared.cookies(for: APIEndpoints.loginURL),
            let cookie = cookies.first(where: {$0.name=="ASP.NET_SessionId"}) {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        sessionId = nil
    }
    
    public func logout() {
        credentials = nil
        removeSessionId()
    }
}

extension URLRequest {
    
    func signed()-> URLRequest? {
        guard let id = EMBUser.shared.sessionId else {
            return nil
        }
        var mutable = self
        mutable.setValue("ASP.NET_SessionId=" + id, forHTTPHeaderField: "Cookie")
        return mutable
    }
    
}
