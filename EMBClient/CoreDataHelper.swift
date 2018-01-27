//
//  CoreDataHelper.swift
//  EMBClient
//
//  Created by Chen Zerui on 12/1/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//

import CoreData

public class CoreDataHelper{
    
    public static let shared = CoreDataHelper()
    
    private let persistentContainer: NSPersistentContainer
    public var mainContext: NSManagedObjectContext{
        return persistentContainer.viewContext
    }
    
    // sync init
    fileprivate init(){
        persistentContainer = NSPersistentContainer(name: "PostRecords")
        
        let group = DispatchGroup()
        group.enter()
        persistentContainer.loadPersistentStores{_, error in
            if error != nil{
                fatalError("Could not initialize CoreData stack: \(error!)")
            }
            group.leave()
        }
        group.wait()
        
    }
    
    func fetch<T>(request: NSFetchRequest<T>)throws-> [T]{
        return try mainContext.fetch(request)
    }
    
    func delete(fetchRequest: NSFetchRequest<NSFetchRequestResult>)throws {
        try mainContext.execute(NSBatchDeleteRequest(fetchRequest: fetchRequest))
    }
    
    public func saveContext() throws {
        if mainContext.hasChanges{
            var error: Error?
            mainContext.performAndWait {
                do{
                    try mainContext.save()
                }
                catch let cdError{
                    error = cdError
                }
            }
            if error != nil{
                throw error!
            }
        }
    }
    
}
