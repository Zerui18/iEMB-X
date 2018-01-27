//
//  EMBUser.swift
//  EMBClient
//
//  Created by Chen Zerui on 12/1/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//

import Foundation

public class EMBUser{
    
    public static let shared = EMBUser()
    
    let userDefaults = UserDefaults.standard
    
    var credentials: (userId: String, password: String)? {
        get{
            if let u = userDefaults.string(forKey: "u"), let p = userDefaults.string(forKey: "p"){
                return (userId: u, password: p)
            }
            return nil
        }
        set{
            if let newCredentials = newValue{
                userDefaults.setValue(newCredentials.userId, forKey: "u")
                userDefaults.setValue(newCredentials.password, forKey: "p")
            }
            else{
                userDefaults.removeObject(forKey: "u")
                userDefaults.removeObject(forKey: "p")
            }
        }
    }
    
    public func hasSavedCredentials()-> Bool{
        return credentials != nil
    }
    
    public func isAuthenticated()-> Bool{
        if let cookies = HTTPCookieStorage.shared.cookies(for: APIEndpoints.loginURL){
            return cookies.contains(where: {$0.name=="ASP.NET_SessionId"})
        }
        return false
    }
    
    public func logout(){
        credentials = nil
        if let cookies = HTTPCookieStorage.shared.cookies(for: APIEndpoints.loginURL), let cookie = cookies.first(where: {$0.name=="ASP.NET_SessionId"}){
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
}
