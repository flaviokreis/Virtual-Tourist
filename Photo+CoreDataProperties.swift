//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Flavio Kreis on 17/02/17.
//  Copyright © 2017 Flavio Kreis. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var image: Data?
    @NSManaged public var pin: Pin?

}
