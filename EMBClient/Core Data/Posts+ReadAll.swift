//
//  Posts+ReadAll.swift
//  EMBClient
//
//  Created by Zerui Chen on 27/3/20.
//  Copyright © 2020 Chen Zerui. All rights reserved.
//

import Foundation

extension Array where Element == Post {
    
    /// Send HEAD requests to all posts in this array, reporting progress and completion.
    public func readAll(progress: @escaping (Int)-> Void, completion: @escaping ()-> Void) {
        // make a copy of self
        var posts = self
        // work off a different queue
        let workingQueue = DispatchQueue(label: "tmp")
        workingQueue.async {
            
            let total = posts.count
            // counter
            var count = 0 {
                didSet {
                    if count == total {
                        // all tasks completed
                        DispatchQueue.main.async {
                            completion()
                            try? CoreDataHelper.shared.saveContext()
                        }
                    }
                }
            }
            
            // recursive function to perform task and invoke next task
            func performTask(_ task: Post) {
                task.markRead { (_, _) in
                    // enforce queue consistency
                    workingQueue.async {
                        // increment counter
                        count += 1
                        
                        // begin new task
                        if let newTask = posts.popLast() {
                            // recursively perform new tasks
                            performTask(newTask)
                        }
                        
                        // progress callback
                        DispatchQueue.main.async {
                            progress(count)
                        }
                    }
                }
            }
            
            // at most 4 cocurrent tasks
            let iniTasks = posts.suffix(4)
            _ = posts.dropLast(iniTasks.count)
            
            // begin recursions
            for task in iniTasks {
                performTask(task)
            }
        }
    }
    
}
