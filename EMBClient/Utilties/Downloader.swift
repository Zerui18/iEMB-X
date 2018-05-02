//
//  Downloader.swift
//  iEMB X
//
//  Created by Chen Changheng on 21/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import Foundation


class Downloader: NSObject, URLSessionDownloadDelegate {
    
    typealias ProgressBlock = (Double)->Void
    typealias CompletionBlock = (Error?)->Void
    
    static func download(file: Attachment, progress: @escaping ProgressBlock, completion: @escaping CompletionBlock)-> Downloader {
        return Downloader(sourceURL: file.url, destinationURL: file.cacheURL, onProgress: progress, onComplete: completion)
    }
    
    init(sourceURL: URL, destinationURL: URL, onProgress block: ProgressBlock? = nil, onComplete handler: CompletionBlock? = nil) {
        super.init()
        session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        task = session.downloadTask(with: URLRequest(url: sourceURL).signed())
        destination = destinationURL
        progressBlock = block
        completionBlock = handler
        EMBClient.shared.reLogin { (_, err) in
            if err != nil {
                self.completionBlock?(err)
            }
            else {
                self.task.resume()
            }
        }
    }
    
    var session: URLSession!
    var task: URLSessionDownloadTask!
    
    var progress: Double = 0.0
    var destination: URL!
    
    var progressBlock: ProgressBlock?
    var completionBlock: CompletionBlock?
        
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        progress = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
        progressBlock?(progress)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        try! FileManager.default.moveItem(at: location, to: destination)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        completionBlock?(error)
    }
    
}
