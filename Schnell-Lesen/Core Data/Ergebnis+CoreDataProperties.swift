//
//  Ergebnis+CoreDataProperties.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 14.05.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//
//

import Foundation
import CoreData


extension Ergebnis {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ergebnis> {
        return NSFetchRequest<Ergebnis>(entityName: "Ergebnis")
    }

    @NSManaged public var datum: NSDate?
    @NSManaged public var minuten: Int32
    @NSManaged public var punkte: Int32
    @NSManaged public var runden: Int32
    @NSManaged public var words: Bool
    @NSManaged public var benutzer: Benutzer?
    
    @objc var sectionIdentifier : String? {
        self.willAccessValue(forKey: "sectionIdentifier")
        var tmp = self.primitiveValue(forKey: "sectionIdentifier") as? String
        self.didAccessValue(forKey: "sectionIdentifier")
        
        if tmp == nil {
            if let timeStamp = self.value(forKey: "datum") as? NSDate {
                /*
                 Sections are organized by month and year. Create the section
                 identifier as a string representing the number (year * 1000) + month;
                 this way they will be correctly ordered chronologically regardless
                 of the actual name of the month.
                 */
                let calendar  = NSCalendar.current
                
                let components = calendar.dateComponents([.year, .month,], from: timeStamp as Date)
                tmp = String(format: "%ld", components.year! * 1000 + components.month!)
                self.setPrimitiveValue(tmp, forKey: "sectionIdentifier")
            }
        }
        return tmp
    }
}
