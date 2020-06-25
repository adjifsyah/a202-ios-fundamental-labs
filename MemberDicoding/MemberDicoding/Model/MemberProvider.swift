//
//  DatabaseHelper.swift
//  MemberDicoding
//
//  Created by Gilang Ramadhan on 24/06/20.
//  Copyright © 2020 Dicoding Indonesia. All rights reserved.
//

import CoreData
import UIKit

class MemberProvider {
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MemberDicoding")
        
        container.loadPersistentStores { storeDesription, error in
            guard error == nil else {
                fatalError("Unresolved error \(error!)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.shouldDeleteInaccessibleFaults = true
        container.viewContext.undoManager = nil
        
        return container
    }()
    
    private func newTaskContext() -> NSManagedObjectContext {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.undoManager = nil
        
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return taskContext
    }
    
    func getAllMember(completion: @escaping(_ members: [NSManagedObject]) -> ()){
        
        let taskContext = persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Member")
        
        do {
            let members = try taskContext.fetch(fetchRequest)
            completion(members)
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func getMember(_ id: Int, completion: @escaping(_ members: NSManagedObject) -> ()){
        
        let taskContext = persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Member")
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "id == \(id)")
        
        do {
            let result = try taskContext.fetch(fetchRequest)
            
            if let member = result.first {
                completion(member)
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    
    func saveMember(_ name: String, _ email: String, _ profession: String, _ about: String, _ image: Data, completion: @escaping() -> ()){
        
        let taskContext = newTaskContext()
        
        if let entity = NSEntityDescription.entity(forEntityName: "Member", in: taskContext) {
            let member = NSManagedObject(entity: entity, insertInto: taskContext)
            getMaxId { (id) in
                member.setValue(id+1, forKeyPath: "id")
                member.setValue(name, forKeyPath: "name")
                member.setValue(email, forKeyPath: "email")
                member.setValue(profession, forKeyPath: "profession")
                member.setValue(about, forKeyPath: "about")
                member.setValue(image, forKeyPath: "image")
            }
            
            do {
                try taskContext.save()
                completion()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    func updateMember(_ id: Int, _ name: String, _ email: String, _ profession: String, _ about: String, _ image: Data, completion: @escaping() -> ()){
        
        let taskContext = newTaskContext()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Member")
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "id == \(id)")
        
        if let result = try? taskContext.fetch(fetchRequest), let member = result.first as? Member{
            member.setValue(name, forKeyPath: "name")
            member.setValue(email, forKeyPath: "email")
            member.setValue(profession, forKeyPath: "profession")
            member.setValue(about, forKeyPath: "about")
            member.setValue(image, forKeyPath: "image")
            
            do {
                try taskContext.save()
                completion()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    func getMaxId(completion: @escaping(_ maxId: Int) -> ()) {
        let taskContext = persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Member")
        
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchLimit = 1
        
        do {
            let lastMember = try taskContext.fetch(fetchRequest)
            if let member = lastMember.first, let position = member.value(forKeyPath: "id") as? Int{
                completion(position)
            } else {
                completion(0)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteAll(completion: @escaping() -> ()) {
        let taskContext = newTaskContext()
        taskContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Member")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeCount
            
            if let batchDeleteResult = try? taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult, batchDeleteResult.result != nil {
                completion()
            }
        }
    }
    
    func deleteMember(_ id: Int, completion: @escaping() -> ()){
        let taskContext = newTaskContext()
        taskContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Member")
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = NSPredicate(format: "id == \(id)")
            
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeCount
            
            if let batchDeleteResult = try? taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult, batchDeleteResult.result != nil {
                completion()
            }
        }
    }
}
