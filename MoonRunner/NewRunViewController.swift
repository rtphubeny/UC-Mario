import UIKit
import CoreData
import CoreLocation
import HealthKit
import MapKit

let DetailSegueName = "RunDetails"
let maxTime = 100
let appColor = UIColor(red:0.99, green:0.36, blue:0.39, alpha:1.0)

let kNameKey = "name";
let kReferenceKey = "reference";
let kAddressKey = "vicinity";
let kLatiudeKeypath = "geometry.location.lat";
let kLongitudeKeypath = "geometry.location.lng";

class NewRunViewController: UIViewController {
    var managedObjectContext: NSManagedObjectContext?

    var run: Run!

    @IBOutlet weak var promptMessage: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!

    @IBOutlet weak var coinsLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    var seconds = maxTime
    var distance = 0.0
    var coins = 0

    // we use this locationManager to read or stop reading runner's location
    // could use kCLLocationAccuracyNearestTenMeters to save battery life
    // another option is kCLLocationAccuracyBest is the users want really accurate readings
    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        _locationManager.activityType = .Fitness // to save power

        // Movement threshold for new events
        _locationManager.distanceFilter = 5.0
        return _locationManager
        }()

    lazy var locations = [CLLocation]()
    lazy var coinLocations = [CLLocation]()
    lazy var timer = NSTimer()

    var alreadySetCoins = false
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)

        startButton.hidden = false
        promptMessage.hidden = false
        timeLabel.hidden = true
        distanceLabel.hidden = true
        coinsLabel.hidden = true
        stopButton.hidden = true
        mapView.hidden = true
    
        locationManager.requestAlwaysAuthorization()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        timer.invalidate()
    }
    
    func timeFormatter(totalSeconds: Int)->String {
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        return String.localizedStringWithFormat("%02d:%02d", minutes, seconds)
    }

    func runPerSecond(timer: NSTimer) {
        seconds--
        
        if seconds <= 0 {
            stopPressed(self)
            locations.removeAll(keepCapacity: false)
        }
        
        // place the coins on the map based on the current location
        if seconds >= 2 && !alreadySetCoins {
            if let lastLocation = self.locations.last {
                let accuracy: CLLocationAccuracy = lastLocation.horizontalAccuracy
                if accuracy < 100.0 {
                    PlacesLoader.sharedInstance().loadPOIsForLocation(lastLocation, radius:300,
                        successHandler: { (response) -> Void in
                            if let status = response["status"] {
                                if let status = response["status"] as? String {
                                    if (status == "OK") {
                                        let places: NSArray = response["results"] as! NSArray
                                        //var temp: [AnyObject] = NSMutableArray() as [AnyObject]
                                        if places.isKindOfClass(NSArray) {
                                            var numCoins = 0
                                            for dataObject : AnyObject in places {
                                                if numCoins == 15 {
                                                    break
                                                }
                                                if let resultsDict = dataObject as? NSDictionary {
                                                    let location: CLLocation = CLLocation(latitude: resultsDict.valueForKeyPath(kLatiudeKeypath)!.doubleValue, longitude: resultsDict.valueForKeyPath(kLongitudeKeypath)!.doubleValue)
                                                    self.coinLocations.append(location)
                                                    if let reference = resultsDict[kReferenceKey] as? String {
                                                        if let name = resultsDict[kNameKey] as? String {
                                                            if let address = resultsDict[kAddressKey] as? String {
                                                                let currentPlace: Place = Place(location: location, reference: reference, name: name, address: address)
                                                                //temp.addObject(currentPlace)
                                                                let annotation: PlaceAnnotation = PlaceAnnotation(place: currentPlace)
                                                                self.mapView.addAnnotation(annotation)
                                                            }
                                                        }
                                                    }
                                                }
                                                numCoins++
                                            }
                                        }
                                        //self.locations = temp.copy()
                                        //NSLog("Locations: %@", locations)
                                    } // end of if statement
                                }
                            }
                            
                        }, errorHandler: { (error) -> Void in
                            // execute
                    })
                    // For testing in simulator
                    /*
                    let location2: CLLocation = CLLocation(latitude: 37.331553, longitude: -122.030800)
                    let currentPlace2: Place = Place(location: location2, reference: "Test2", name: "Test2", address: "Test2")
                    let annotation2: PlaceAnnotation = PlaceAnnotation(place: currentPlace2)
                    self.mapView.addAnnotation(annotation2)
                    */
                } // end
            }
            alreadySetCoins = true
        }
        
        if seconds == maxTime {
             distance = 0.0
        }
        
        timeLabel.text = "Time Left - " + timeFormatter(seconds)
    
//    let formatter = NSLengthFormatter()
//    formatter.numberFormatter.maximumFractionDigits = 2
//    // defaults to medium unit style
//    let lengthFormatterUnit: NSLengthFormatterUnit = HKUnit.lengthFormatterUnitFromUnit(HKUnit.meterUnit())
//    let distanceResult = formatter.stringFromValue(distanceValue, unit: lengthFormatterUnit)
//    ORIGINAL METHOD OF CONVERTING DOUBLE TO STRING WITH TWO DECIMAL PRECISION
    
        let distanceQuantity = HKQuantity(unit: HKUnit.meterUnit(), doubleValue: distance)
        let distanceValue = distanceQuantity.doubleValueForUnit(HKUnit.meterUnit())
        distanceLabel.text = "Distance - " + String.localizedStringWithFormat("%.2f%@", distanceValue, "m")
    
        coinsLabel.text = "Coins Collected - " + String.localizedStringWithFormat("%d%", coins) + "/15"
    }

    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }

    func saveRun() {
        let savedRun = NSEntityDescription.insertNewObjectForEntityForName("Run", inManagedObjectContext: managedObjectContext!) as! Run
        savedRun.coins = coins
        savedRun.distance = distance
        savedRun.duration = maxTime - seconds
        savedRun.timestamp = NSDate()

        var savedLocations = [Location]()
        for location in locations {
            let savedLocation = NSEntityDescription.insertNewObjectForEntityForName("Location",
                inManagedObjectContext: managedObjectContext!) as! Location
            savedLocation.timestamp = location.timestamp
            savedLocation.latitude = location.coordinate.latitude
            savedLocation.longitude = location.coordinate.longitude
            savedLocations.append(savedLocation)
        }
        
        savedRun.locations = NSOrderedSet(array: savedLocations)
        run = savedRun
        
//        for location in locations {
//            let howRecent = location.timestamp.timeIntervalSinceNow
//            
//            // check to make sure the data is accurate enough and that the data is recent enough
//            if abs(howRecent) < 10 && location.horizontalAccuracy < 20 {
//                // update distance; only checking horizontal here because vertical is change in altitude (useful when the runner is going up a hill but we ignore for simplicity here)
//                if self.locations.count > 0 {
//                    var coords = [CLLocationCoordinate2D]()
//                    mapView.removeOverlay(MKPolyline(coordinates: &coords, count: coords.count))
//                }
//            }
//        }
        
        var error: NSError?
        let success: Bool
        do {
            try managedObjectContext!.save()
            success = true
        } catch let error1 as NSError {
            error = error1
            success = false
        }
        if !success {
            print("Could not save the run!")
        }
    }

  @IBAction func startPressed(sender: AnyObject) {
    seconds = maxTime
    distance = 0.0
    locations.removeAll(keepCapacity: false)
    
    startButton.hidden = true
    promptMessage.hidden = true
    timeLabel.hidden = false
    distanceLabel.hidden = false
    coinsLabel.hidden = false
    stopButton.hidden = false
    
    timer = NSTimer.scheduledTimerWithTimeInterval(1,
        target: self,
        selector: "runPerSecond:",
        userInfo: nil,
        repeats: true)
    startLocationUpdates()
    // schedule an update every second

    mapView.hidden = false
  }

  @IBAction func stopPressed(sender: AnyObject) {
    saveRun()
    performSegueWithIdentifier(DetailSegueName, sender: nil)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let detailViewController = segue.destinationViewController as? DetailViewController {
      detailViewController.run = run
    }
  }
}

// MARK: - MKMapViewDelegate
extension NewRunViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer! {
        if !overlay.isKindOfClass(MKPolyline) {
            return nil
        }
        
        let polyline = overlay as! MKPolyline
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = appColor
        renderer.lineWidth = 3
        return renderer
    }
    
    // Use a golden coin as a location marker instead of the default location pin
    // Function gets called automatically when an annotation is created
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annView: MKAnnotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "currentloc")
        annView.image = UIImage(named: "golden_coin.png")
        annView.canShowCallout = true
        return annView
    }
}


// use this to get update using location manager
extension NewRunViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let howRecent = location.timestamp.timeIntervalSinceNow
            
            // check to make sure the data is accurate enough and that the data is recent enough
            if abs(howRecent) < 10 && location.horizontalAccuracy < 50 {
                // update distance; only checking horizontal here because vertical is change in altitude (useful when the runner is going up a hill but we ignore for simplicity here)
                if self.locations.count > 0 {
                    distance += location.distanceFromLocation(self.locations.last!)   // calculate distance from last saved location in the locations array
                    
                    var coords = [CLLocationCoordinate2D]()
                    coords.append(self.locations.last!.coordinate)
                    coords.append(location.coordinate)
                    
                    let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500)
                    mapView.setRegion(region, animated: true)
                    
                    mapView.addOverlay(MKPolyline(coordinates: &coords, count: coords.count))
                }
                
                //save location
                self.locations.append(location)
            }
        }
        // Check if we hit a coin
        let location: AnyObject? = locations.last
        if let location: AnyObject = location {
            let lastLocation = location as! CLLocation
            for annotation: MKAnnotation in mapView.annotations {
                let coord: CLLocationCoordinate2D = annotation.coordinate
                
                let mycurrentlat = lastLocation.coordinate.latitude
                let mycurrentlon = lastLocation.coordinate.longitude
                
                let lat1 = coord.latitude + 0.00012
                let lat2 = coord.latitude - 0.00012
                
                let lon1 = coord.longitude + 0.00012
                let lon2 = coord.longitude - 0.00012
                
                if ((mycurrentlat <= lat1) && (mycurrentlon <= lon1) && (mycurrentlat >= lat2) && (mycurrentlon >= lon2)) {
                    //NSLog("PIN coordinates = %f,%f, %@", coord.latitude, coord.longitude, annotation.title)
                    mapView.removeAnnotation(annotation)
                    coins++
                    //var temp: [AnyObject] = NSMutableArray()
                    /*
                    for place: Place in locations {
                    if place.placeName != annotation.title {
                    temp.addObject(place)
                    }
                    }
                    self.locations = temp.copy()
                    */
                }
            }
        }
    }
}

