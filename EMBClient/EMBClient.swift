//
//  EMBClient.swift
//  iEMB X
//
//  Created by Chen Changheng on 14/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import Foundation
import CoreData


public class EMBClient {
    
    public static let shared = EMBClient(dataStoreHelper: CoreDataHelper.shared)
    
    fileprivate var dataStoreHelper: CoreDataHelper
    
    public var allPosts: [Int:[Post]]
    
    fileprivate func newestPostIndex(forBoard board: Int)-> Int {
        return Int(allPosts[board]?.first?.id ?? -1)
    }
    
    public init(dataStoreHelper: CoreDataHelper) {
        self.dataStoreHelper = dataStoreHelper
        allPosts = Dictionary(uniqueKeysWithValues: zip([1039, 1048, 1049, 1050, 1053], [[Post]](repeating: [], count: 5)))
        for post in Post.fetchAll() {
            allPosts[Int(post.board)]!.append(post)
        }
        allPosts = allPosts.mapValues {
            $0.sorted(by: { $0.id>$1.id })
        }
    }
    
}

public extension EMBClient {
    
    public func login(username: String, password: String, then completion: @escaping (Bool, Error?)->Void) {
        var loginRequest = URLRequest(url: APIEndpoints.loginURL)
        loginRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        loginRequest.httpMethod = "post"
        loginRequest.httpBody = "username=\(username)&password=\(password)&submitbut=Submit".data(using: .utf8)
        
        EMBUser.shared.logout()
        
        URLSession.shared.dataTask(with: loginRequest) { (_, _, error) in
            if error != nil {
                completion(false, error)
            }
            else {
                if EMBUser.shared.saveSessionId() {
                    EMBUser.shared.credentials = (userId: username, password: password)
                    completion(true, nil)
                }
                else {
                    completion(false, NSError(domain: "com.Zerui.EMBClient.AuthError", code: 403, userInfo: [NSLocalizedDescriptionKey : "Did not receive valid data from server, this is probably due to authentication failure."]))
                }
            }
        }.resume()
    }
    
    public func reLogin(then completion: @escaping (Bool, Error?)->Void) {
        let user = EMBUser.shared.credentials!
        login(username: user.userId, password: user.password, then: completion)
    }
    
}

extension EMBClient {
    
    private func extractTables(from html: String)-> [String] {
        var strs = [String]()
        for tabPattern in [unreadTableStart, readTableStart] {
            let startIndex = html.range(of: tabPattern)!.upperBound
            var tab = String(html[startIndex...])
            let endIndex = tab.range(of: tableEnd)!.lowerBound
            tab = String(tab[..<endIndex])
            strs.append(tab)
        }
        return strs
    }
    
    private func _extractPosts(from table: String, markRead: Bool, board: Int)-> [Post] {
        let rows = table.components(separatedBy: "<tr>")[1...]
        var posts = [Post]()
        for row in rows {
            if let dateMatch = row ~ dateRegex,
                dateMatch.numberOfRanges > 1,
                let contentMatch = row ~ contentRegex,
                contentMatch.numberOfRanges > 3,
                let authorMatch = row ~ authorRegex,
                authorMatch.numberOfRanges > 1,
                let importanceMatch = row ~ importanceRegex,
                importanceMatch.numberOfRanges > 1 {
                let copy = row as NSString
                let id = Int(copy.substring(with: contentMatch.range(at: 1)))!
                let board = Int(copy.substring(with: contentMatch.range(at: 2)))!
                if self.newestPostIndex(forBoard: board) < id {
                    posts.append(Post(
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
        try? CoreDataHelper.shared.saveContext()
        return posts
    }
    
    public func extractPosts(from tables: [String], board: Int)-> [Post] {
        var id = 0
        return tables.reduce(into: [Post]()) { (posts, table) in
            posts.append(contentsOf: _extractPosts(from: table, markRead: id == 1, board: board))
            id += 1
        }
    }
    
    public func updatePosts(forBoard board: Int, completion: @escaping([Post]?, Error?)->Void) {
        loadPage(request: URLRequest(url: APIEndpoints.boardURL(forId: board))) { (html, error) in
            guard error == nil else {
                completion(nil, error)
                return
            }
            
            let boards = self.extractTables(from: html!)
            let posts = self.extractPosts(from: boards, board: board).sorted(by: { $0.id>$1.id })
            self.allPosts[board]!.insert(contentsOf: posts, at: 0)
            do {
                try self.dataStoreHelper.saveContext()
            }
            catch {
                print("error saving context")
            }
            completion(posts, nil)
        }
    }
    
    /**
     Deletes all locally cached attachments & contents of the posts. Used for clearing out disk space.
     */
    public func trimCache() throws {
        try FileManager.default.removeItem(at: cachedFilesURL)
        try FileManager.default.createDirectory(at: cachedFilesURL, withIntermediateDirectories: false, attributes: nil)
        try CoreDataHelper.shared.delete(fetchRequest: Attachment.fetchRequest())
        allPosts.forEach {
            $0.value.forEach {
                $0.content = nil
                $0.contentData = nil
            }
        }
        try CoreDataHelper.shared.saveContext()
    }
    
    /**
     Deletes all cookies, cached posts & attachments and clears all posts from memory. Used for wiping user-data when logging out / re-logging in.
     */
    public func resetCache() throws {
        allPosts = Dictionary(uniqueKeysWithValues: zip([1039, 1048, 1049, 1050, 1053], [[Post]](repeating: [], count: 5)))
        HTTPCookieStorage.shared.removeCookies(since: Date(timeIntervalSince1970: 0))
        try FileManager.default.removeItem(at: cachedFilesURL)
        try FileManager.default.createDirectory(at: cachedFilesURL, withIntermediateDirectories: false, attributes: nil)
        try CoreDataHelper.shared.delete(fetchRequest: Post.fetchRequest())
        try CoreDataHelper.shared.delete(fetchRequest: Attachment.fetchRequest())
        try CoreDataHelper.shared.saveContext()
    }
    
    
    /**
     Loads data with the provided request on URLSession.shared. Will validate received data to check for auth-error. Retries the request after re-authentication
     */
    func loadPage(request: URLRequest, completion: @escaping (String?, Error?)->Void) {
        
        func authFailed() {
            completion(nil, NSError(domain: "com.Zerui.EMBClient.AuthError", code: 403, userInfo: [NSLocalizedDescriptionKey : "Did not receive valid data from server, this is probably due to authentication failure."]))
            NotificationCenter.default.post(name: .embLoginCredentiaInvalidated, object: nil)
        }
        
        guard let request1 = request.signed() else {
            authFailed()
            return
        }
        
        URLSession.shared.dataTask(with: request1) { (data, res, err) in
            guard err == nil else {
                completion(nil, err)
                return
            }
            
            guard isResponseValid(res!) else {
                
                // has repsponse but invalid
                // might be dut to outdated auth cookie
                self.reLogin { (success, error) in
                    guard error == nil else {
                        completion(nil, error)
                        return
                    }
                    
                    // retry fetching page
                    URLSession.shared.dataTask(with: request.signed()!) { (data, res, err) in
                        guard let data = data else {
                            completion(nil, error!)
                            return
                        }
                        
                        guard isResponseValid(res!) else {
                            authFailed()
                            return
                        }
                        
                        completion(String(data: data, encoding: .utf8), nil)
                    }.resume()
                }
                
                return
            }
            
            completion(String(data: data!, encoding: .utf8), nil)
            
        }.resume()
    }
    
}

fileprivate func isResponseValid(_ response: URLResponse)-> Bool {
    return response.expectedContentLength > 2066
}
