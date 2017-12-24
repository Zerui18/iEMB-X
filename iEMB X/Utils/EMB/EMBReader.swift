//
//  File.swift
//  iEMB X
//
//  Created by Chen Changheng on 14/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import Foundation
import CoreData


class EMBReader{
    
    static func login(username: String, password: String, then completion: @escaping (Bool, Error?)->Void){
        var loginRequest = URLRequest(url: Constants.loginURL)
        loginRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        loginRequest.httpMethod = "post"
        loginRequest.httpBody = "username=\(username)&password=\(password)&submitbut=Submit".data(using: .utf8)
        URLSession.shared.dataTask(with: loginRequest) { (_, _, error) in
            if error != nil{
                completion(false, error)
            }
            else{
                if isAuthenticated(){
                    isLoggedIn = true
                    completion(true, nil)
                }
                else{
                    completion(false, NSError())
                }
            }
        }.resume()
    }
    
    static func reLogin(then completion: @escaping (Bool, Error?)->Void){
        let user = storedUser()!
        login(username: user.u, password: user.p, then: completion)
    }
    
    static var isLoggedIn = false
    
    static func storedUser()-> (u: String, p: String)?{
        if let u = userDefaults.string(forKey: "u"), let p = userDefaults.string(forKey: "p"){
            return (u: u, p: p)
        }
        return nil
    }
    
    static func isAuthenticated()-> Bool{
        if let cookies = HTTPCookieStorage.shared.cookies(for: Constants.loginURL){
            return cookies.contains(where: {$0.name=="ASP.NET_SessionId"})
        }
        return false
    }
    
    static func extractTables(from html: String)-> [String]{
        var strs = [String]()
        for tabPattern in [Constants.unreadTableStart, Constants.readTableStart]{
            let startIndex = html.range(of: tabPattern)!.upperBound
            var tab = String(html[startIndex...])
            let endIndex = tab.range(of: Constants.tableEnd)!.lowerBound
            tab = String(tab[..<endIndex])
            strs.append(tab)
        }
        return strs
    }
    
    static func _extractPosts(from table: String, markRead: Bool, board: Int)-> [Post]{
        let rows = table.components(separatedBy: "<tr>")[1...]
        var posts = [Post]()
        for row in rows{
            if let dateMatch = row ~ Constants.dateRegex,
                dateMatch.numberOfRanges > 1,
                let contentMatch = row ~ Constants.contentRegex,
                contentMatch.numberOfRanges > 3,
                let authorMatch = row ~ Constants.authorRegex,
                authorMatch.numberOfRanges > 1,
                let importanceMatch = row ~ Constants.importanceRegex,
                importanceMatch.numberOfRanges > 1{
                let copy = row as NSString
                let id = copy.substring(with: contentMatch.range(at: 1)).toInt!
                let board = copy.substring(with: contentMatch.range(at: 2)).toInt!
                if largestPostIds[board]! < id{
                    posts.append(Post.init(
                        title: copy.substring(with: contentMatch.range(at: 3)).removingHTMLEncoding,
                        author: copy.substring(with: authorMatch.range(at: 1)),
                        date: copy.substring(with: dateMatch.range(at: 1)),
                        id: id,
                        board: board,
                        importance: Importance(rawValue: copy.substring(with: importanceMatch.range(at: 1)))!,
                        isRead: markRead)
                    )
                }
            }
        }
        saveContext()
        return posts
    }
    
    static func extractPosts(from tables: [String], board: Int)-> [Post]{
        var id = 0
        return tables.reduce(into: [Post]()) { (posts, table) in
            posts.append(contentsOf: _extractPosts(from: table, markRead: id == 1, board: board))
            id += 1
        }
    }
    
    static func updatePostsFor(board: Int, completion: @escaping([Post]?)->Void){
        getHTML(request: URLRequest(url: Constants.boardURLFor(id: board))) { (html, error) in
            if error != nil{
                completion(nil)
            }
            else{
                let boards = extractTables(from: html!)
                let posts = extractPosts(from: boards, board: board)
                allPosts[board]?.insert(contentsOf: posts.sorted(by: {$0.id>$1.id}), at: 0)
                largestPostIds[board] = Int(allPosts[board]!.first?.id ?? 0)
                saveContext{_ in
                    completion(posts)
                }
            }
        }
    }
    
    
    static func resetCache() throws{
        isLoggedIn = false
        HTTPCookieStorage.shared.removeCookies(since: Date(timeIntervalSince1970: 0))
        try FileManager.default.removeItem(at: Constants.cachedFilesURL)
        try FileManager.default.createDirectory(at: Constants.cachedFilesURL, withIntermediateDirectories: false, attributes: nil)
        try context.execute(NSBatchDeleteRequest(fetchRequest: Post.fetchRequest()))
        try context.execute(NSBatchDeleteRequest(fetchRequest: Attachment.fetchRequest()))
        try context.save()
        backgroungFetchInterval = 30*60
    }
    
}
