
import Foundation
import CoreData

class Location: NSManagedObject {

    @NSManaged var timestamp: NSDate
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var run: NSManagedObject

}
