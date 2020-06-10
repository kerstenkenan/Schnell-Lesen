//
//  Benutzer+CoreDataProperties.swift
//  Schnell-Lesen
//
//  Created by Kersten Weise on 03.04.19.
//  Copyright © 2019 Kersten Weise. All rights reserved.
//
//

import Foundation
import CoreData


extension Benutzer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Benutzer> {
        return NSFetchRequest<Benutzer>(entityName: "Benutzer")
    }

    @NSManaged public var ausgewaehlt: Bool
    @NSManaged public var datum: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var ergebnis: NSSet?

}

// MARK: Generated accessors for ergebnis
extension Benutzer {

    @objc(addErgebnisObject:)
    @NSManaged public func addToErgebnis(_ value: Ergebnis)

    @objc(removeErgebnisObject:)
    @NSManaged public func removeFromErgebnis(_ value: Ergebnis)

    @objc(addErgebnis:)
    @NSManaged public func addToErgebnis(_ values: NSSet)

    @objc(removeErgebnis:)
    @NSManaged public func removeFromErgebnis(_ values: NSSet)

}
