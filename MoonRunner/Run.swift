
import Foundation
import CoreData

class Run: NSManagedObject {
    // @NSManaged var coins: NSNumber
    @NSManaged var duration: NSNumber
    @NSManaged var distance: NSNumber
    @NSManaged var timestamp: NSDate
    @NSManaged var locations: NSOrderedSet

}
