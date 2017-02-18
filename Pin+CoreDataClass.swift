//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Flavio Kreis on 17/02/17.
//  Copyright © 2017 Flavio Kreis. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name")
        }
    }

}
