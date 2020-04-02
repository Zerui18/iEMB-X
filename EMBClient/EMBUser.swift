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
    
    var sessionId: String? {
        get {
            return userDefaults.string(forKey: "sessId")
        }
        set {
            userDefaults.set(newValue, forKey: "sessId")
        }
    }
    
    var authToken: String? {
        get {
            userDefaults.string(forKey: "authT")
        }
        set {
            userDefaults.set(newValue, forKey: "authT")
        }
    }
    
    public func hasSavedCredentials()-> Bool {
        return credentials != nil
    }
    
    public func isAuthenticated()-> Bool {
        return sessionId != nil && authToken != nil
    }
    
    public func saveCookies()-> Bool {
        guard let cookie1 = cookie(named: "ASP.NET_SessionId"),
                    let cookie2 = cookie(named: "AuthenticationToken")
            else {
            return false
        }
        sessionId = cookie1
        authToken = cookie2
        return true
    }
    
    func clearCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date(timeIntervalSince1970: 0))
        sessionId = nil
        authToken = nil
    }
    
    public func logout() {
        credentials = nil
        clearCookies()
    }
}
