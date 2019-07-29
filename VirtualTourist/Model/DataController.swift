//
//  DataController.swift
//  VirtualTourist
//
//  Created by Mohamed Metwaly on 2019-05-22.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    let persistentController:NSPersistentContainer
    var viewContext:NSManagedObjectContext {
        return persistentController.viewContext
    }
    
    init(modelName:String){
        persistentController = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil){
        persistentController.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
}
