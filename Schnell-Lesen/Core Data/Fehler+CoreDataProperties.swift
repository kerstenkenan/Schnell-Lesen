//
//  Fehler+CoreDataProperties.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 03.04.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//
//

import Foundation
import CoreData


extension Fehler {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Fehler> {
        return NSFetchRequest<Fehler>(entityName: "Fehler")
    }

    @NSManaged public var deviceName: String?
    @NSManaged public var datum: NSDate?
    @NSManaged public var wort: String?
    @NSManaged public var erkanntesWort: String?

}
