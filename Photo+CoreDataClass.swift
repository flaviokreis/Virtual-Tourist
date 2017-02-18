//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Flavio Kreis on 17/02/17.
//  Copyright © 2017 Flavio Kreis. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
    convenience init(data : Data, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.image = data
        } else {
            fatalError("Unable to find Entity name")
        }
    }

}
