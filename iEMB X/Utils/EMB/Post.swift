//
//  Post.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import CoreData
import UIKit

enum Importance: String{
    case urgent = "C"
    case important = "B"
    case information = "A"
}

@objc(Post)
class Post: NSManagedObject{
    
    convenience init(title: String, author: String, date: String, id: Int, board: Int, importance: Importance, isRead: Bool){
        self.init(entity: NSEntityDescription.entity(forEntityName: "Post", in: context)!, insertInto: context)
        self.title = title
        self.author = author
        self.date = date
        self.id = Int64(id)
        self.board = Int64(board)
        self.importanceString = importance.rawValue
        self.isRead = isRead
        self.titleLower = title.lowercased()
    }


    lazy var importance: Importance = {
        return Importance(rawValue: self.importanceString!)!
    }()
    
    lazy var titleLower: String = {
        return self.title!.lowercased()
    }()

    var content: NSMutableAttributedString?
    var isLoadingMessage = false
    
    private var completionBlock: ((Error?)->Void)?
    
    func loadContent(completion: @escaping (Error?)->Void){
        self.completionBlock = completion
        if isLoadingMessage{
            return
        }
        isLoadingMessage = true
        if let data = self.contentData as Data?{
            do{
                self.content = try NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil)
            }
            catch{
                isLoadingMessage = false
                completion(error)
            }
            isLoadingMessage = false
            completion(nil)
        }
        else{
            let postURL = "https://iemb.hci.edu.sg/Board/content/\(self.id)?board=\(self.board)".toURL!
            
            func process(html: String){
                self.attachments = []
                self.isLoadingMessage = false
                if let index = html.range(of: "id=\"hyplink-css-style\">")?.upperBound{
                    
                    var extract = String(html[index...])
                    let endIndex = extract.range(of: "<script src=\"/Scripts")!.lowerBound
                    extract = String(extract[..<endIndex])
                    
                    // extract iframes
                    Constants.iframeRegex.matches(in: extract, options: [], range: NSMakeRange(0, extract.count)).forEach{
                        if $0.numberOfRanges == 2{
                            let url = URL(string: (extract as NSString).substring(with: $0.range(at: 1)), relativeTo: postURL)!
                            self.addToAttachments(Attachment(url: url, name: url.host ?? "link", type: .embed, post: self))
                        }
                    }
                    
                    //remove iframes
                    extract = Constants.iframeRemovalRegex.stringByReplacingMatches(in: extract, options: [], range: NSMakeRange(0, extract.count), withTemplate: "")
                    
                    do{
                        // initialize attributed string
                        self.content = try NSMutableAttributedString(data: extract.data(using: .utf8)!, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
                        // fix font (size + 3) & (font = system)
                        self.content!.enumerateAttribute(named: .font){ (attribute, range, _) in
                            let font = attribute as! UIFont
                            let newFont = UIFont.systemFont(ofSize: font.pointSize+3)
                            self.content!.addAttribute(.font, value: newFont, range: range)
                        }
                        // remove all background colors
                        self.content!.addAttribute(NSAttributedStringKey.backgroundColor, value: UIColor.clear, range: NSRange(location: 0, length: self.content!.length))
                        
                        self.contentData = try self.content!.data(from: NSRange(location: 0, length: self.content!.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]) as NSData
                    }
                    catch{
                        print("error decoding extracted html ", error)
                        self.completionBlock?(error)
                        return
                    }
                    let fileMatches = Constants.fileRegex.matches(in: html, options: [], range: NSRange.init(location: 0, length: html.count))
                    let copy = html as NSString
                    for match in fileMatches where match.numberOfRanges > 4{
                        let name = copy.substring(with: match.range(at: 1))
                        let url = "https://iemb.hci.edu.sg/Board/ShowFile?t=2&ctype=\(copy.substring(with: match.range(at: 4)))&id=\(copy.substring(with: match.range(at: 2)))&file=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&boardId=\(copy.substring(with: match.range(at: 3)))".toURL!
                        self.addToAttachments(Attachment(url: url, name: name, type: .file, post: self))
                    }
                    self.canRespond = html.contains("<form id=\"replyForm\"")
                    self.isRead = true
                    DispatchQueue.main.async {
                        if let index = allPosts[Int(self.board)]!.index(of: self), let cell = menuViewController.presentedBoardVC?.tableView.visibleCell(at: IndexPath(row: index, section: 0)){
                            (cell as! PostCell).updateWith(post: self)
                        }
                    }
                }
                
            }
            getHTML(request: URLRequest(url: postURL)) { (html, error) in
                if error != nil{
                    self.completionBlock?(error)
                }
                else{
                    process(html: html!)
                    self.completionBlock?(nil)
                }
                saveContext()
            }
        }
    }
    
    func postResponse(option: String, content: String, completion: @escaping(Error?)-> Void){
        var request = URLRequest(url: "https://iemb.hci.edu.sg/board/ProcessResponse".toURL!)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "post"
        request.httpBody = "boardid=\(board)&topic=\(id)&replyto=0&UserRating=\(option)&replyContent=\(content)&PostMessage=Post  Reply&Cancel=Cancel".data(using: .utf8)
        getHTML(request: request) { (_, error) in
            if error == nil{
                self.responseOption = option
                self.responseContent = content
                saveContext()
            }
            completion(error)
        }
    }
    
    func compoundMessage()-> NSMutableAttributedString?{
        if let c = content{
            let text = NSMutableAttributedString(string: title!+"\n", attributes: [.font: titleFont])
            text.append(NSAttributedString(string: "\n", attributes: [.font: UIFont.systemFont(ofSize: 5)]))
            text.append(NSAttributedString(string: author!+"  On  "+date!+"\n\n\n", attributes: [.font: miscFont, .foregroundColor: UIColor.darkGray]))
            text.append(c)
            return text
        }
        return nil
    }
    
}

extension Post{
    static func fetchAll()-> [Post]{
        return try! context.fetch(Post.fetchRequest())
    }
    
    static func initializePosts(){
        if !isPostsInitialized{
            isPostsInitialized = true
            fetchAll().forEach{
                allPosts[Int($0.board)]?.append($0)
            }
            allPosts = allPosts.mapValues{
                $0.sorted(by: {$0.id>$1.id})
            }
            largestPostIds = allPosts.mapValues({Int($0.first?.id ?? 0)})
        }
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
