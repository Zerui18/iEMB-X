//
//  Post.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import CoreData
import UIKit

public enum Importance: String {
    case urgent = "C", important = "B", information = "A"
}

@objc(Post)
public class Post: NSManagedObject {
    
    convenience init(title: String, author: String, date: String, id: Int, board: Int, importance: Importance, isRead: Bool) {
        self.init(entity: NSEntityDescription.entity(forEntityName: "Post", in: CoreDataHelper.shared.mainContext)!, insertInto: CoreDataHelper.shared.mainContext)
        self.title = title
        self.author = author
        self.date = date
        self.id = Int64(id)
        self.board = Int64(board)
        self.importanceString = importance.rawValue
        self.isRead = isRead
        self.titleLower = title.lowercased()
    }


    public lazy var importance: Importance = {
        return Importance(rawValue: self.importanceString!)!
    }()
    
    public lazy var titleLower: String = {
        return self.title!.lowercased()
    }()

    public var content: NSMutableAttributedString?
    var isLoadingMessage = false
    
    private var callback: ((Error?)->Void)?
    
    public func loadContent(completion: @escaping (Error?)->Void) {
        self.callback = completion
        if isLoadingMessage {
            return
        }
        isLoadingMessage = true
        if let data = self.contentData as Data? {
            do {
                self.content = try NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil)
            }
            catch {
                isLoadingMessage = false
                completion(error)
            }
            isLoadingMessage = false
            completion(nil)
        }
        else {
            let postURL = APIEndpoints.postURL(forId: Int(id), boardId: Int(board))
            print(postURL)
            
            func processAndSave(html: String) {
                self.attachments = []
                self.isLoadingMessage = false
                if let index = html.range(of: "id=\"hyplink-css-style\">")?.upperBound {
                    
                    var extract = String(html[index...])
                    let endIndex = extract.range(of: "<script src=\"/Scripts")!.lowerBound
                    extract = String(extract[..<endIndex])
                    
                    // extract iframes
                    iframeRegex.matches(in: extract, options: [], range: NSMakeRange(0, extract.count)).forEach {
                        if $0.numberOfRanges == 2 {
                            let url = URL(string: (extract as NSString).substring(with: $0.range(at: 1)), relativeTo: postURL)!
                            self.addToAttachments(Attachment(url: url, name: url.host ?? "link", type: .embedding))
                        }
                    }
                    
                    // remove iframes
                    extract = iframeRemovalRegex.stringByReplacingMatches(in: extract, options: [], range: NSMakeRange(0, extract.count), withTemplate: "")
                    
                    do {
                        // initialize attributed string
                        self.content = try NSMutableAttributedString(data: extract.data(using: .utf8)!, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
                        let fullRange = NSRange(location: 0, length: self.content!.length)
                        
                        // fix font (size + 3) & (font = system)
                        self.content!.enumerateAttribute(.font, in: fullRange) { (attribute, range, _) in
                            let font = attribute as! UIFont
                            let newFont = UIFont.systemFont(ofSize: font.pointSize+3)
                            self.content!.addAttribute(.font, value: newFont, range: range)
                        }
                        // remove all background colors
                        self.content!.addAttribute(.backgroundColor, value: UIColor.clear, range: fullRange)
                        
                        self.contentData = try self.content!.data(from: fullRange,
                                                                  documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]) as NSData
                    }
                    catch {
                        print("error decoding extracted html ", error)
                        self.callback?(error)
                        return
                    }
                    let fileMatches = fileRegex.matches(in: html, options: [], range: NSRange.init(location: 0, length: html.count))
                    let copy = html as NSString
                    for match in fileMatches where match.numberOfRanges > 4 {
                        let name = copy.substring(with: match.range(at: 1))
                        let url = URL(string: "https://iemb.hci.edu.sg/Board/ShowFile?t=2&ctype=\(copy.substring(with: match.range(at: 4)))&id=\(copy.substring(with: match.range(at: 2)))&file=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&boardId=\(copy.substring(with: match.range(at: 3)))")!
                        self.addToAttachments(Attachment(url: url, name: name, type: .file))
                    }
                    self.canReply = html.contains("<form id=\"replyForm\"")
                    self.isRead = true
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .postContentDidLoad, object: self)
                    }
                }
                
            }
            
            // load post html and pass it into the process(html:) function
            EMBClient.shared.loadPage(request: URLRequest(url: postURL)) { (html, error) in
                if error != nil {
                    self.callback?(error)
                }
                else {
                    processAndSave(html: html!)
                    self.callback?(nil)
                    try? CoreDataHelper.shared.saveContext()
                }
                self.callback = nil
            }
        }
    }
    
    public func sendReply(option: String, content: String, completion: @escaping(Error?)-> Void) {
        let content = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        var request = URLRequest(url: APIEndpoints.replyURL)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "post"
        request.httpBody = "boardid=\(board)&topic=\(id)&replyto=0&UserRating=\(option)&replyContent=\(content)&PostMessage=Post  Reply&Cancel=Cancel".data(using: .utf8)
        EMBClient.shared.loadPage(request: request) { (_, error) in
            if error == nil {
                self.responseOption = option
                self.responseContent = content
                do {
                    try CoreDataHelper.shared.saveContext()
                    completion(nil)
                }
                catch {
                    completion(error)
                }
            }
        }
    }
    
    public func compoundMessage()-> NSMutableAttributedString? {
        if let c = content {
            // enforce uni-colored text for dark mode compatibility (iOS 13+)
            if #available(iOS 13.0, *) {
                c.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: c.length))
            }
            
            // prepare attributes
            var titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
            if #available(iOS 13.0, *) {
                titleAttributes[.foregroundColor] = UIColor.label
            }
            var subtitleAttributes: [NSAttributedString.Key: Any] = [.font: miscFont]
            if #available(iOS 13.0, *) {
                subtitleAttributes[.foregroundColor] = UIColor.secondaryLabel
            }
            else {
                subtitleAttributes[.foregroundColor] = UIColor.darkGray
            }
            
            let text = NSMutableAttributedString(string: title!+"\n", attributes: titleAttributes)
            text.append(NSAttributedString(string: "\n", attributes: [.font: UIFont.systemFont(ofSize: 5)]))
            text.append(NSAttributedString(string: author!+" on "+date!+"\n\n\n", attributes: subtitleAttributes))
            text.append(c)
            return text
        }
        return nil
    }
    
}

extension Post {
    static func fetchAll()-> [Post] {
        return try! CoreDataHelper.shared.fetch(request: Post.fetchRequest())
    }
}

fileprivate var isPostsInitialized = false

fileprivate let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
fileprivate let miscFont = UIFont.systemFont(ofSize: 18, weight: .medium)

fileprivate var dateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "dd-MMM-yy"
    return f
}()
