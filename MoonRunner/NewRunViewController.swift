import UIKit
import CoreData
import CoreLocation
import HealthKit
import MapKit

let DetailSegueName = "RunDetails"

class NewRunViewController: UIViewController {
    var managedObjectContext: NSManagedObjectContext?

    var run: Run!

    @IBOutlet weak var promptMessage: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var averageSpeed: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!

    @IBOutlet weak var mapView: MKMapView!

    var seconds = 0.0
    var distance = 0.0

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
  lazy var timer = NSTimer()

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    startButton.hidden = false
    promptMessage.hidden = false

    timeLabel.hidden = true
    distanceLabel.hidden = true
    averageSpeed.hidden = true
    stopButton.hidden = true
    mapView.hidden = true
    
    locationManager.requestAlwaysAuthorization()
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    timer.invalidate()
  }

  func runPerSecond(timer: NSTimer) {
    seconds++
    
    let secondsQuantity = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: seconds)
    timeLabel.text = "Time: " + secondsQuantity.description
    
//    let formatter = NSLengthFormatter()
//    formatter.numberFormatter.maximumFractionDigits = 2
//    // defaults to medium unit style
//    let lengthFormatterUnit: NSLengthFormatterUnit = HKUnit.lengthFormatterUnitFromUnit(HKUnit.meterUnit())
//    let distanceResult = formatter.stringFromValue(distanceValue, unit: lengthFormatterUnit)
//    ORIGINAL METHOD OF CONVERTING DOUBLE TO STRING WITH TWO DECIMAL PRECISION
    
    let distanceQuantity = HKQuantity(unit: HKUnit.meterUnit(), doubleValue: distance)
    let distanceValue = distanceQuantity.doubleValueForUnit(HKUnit.meterUnit())
    distanceLabel.text = "Distance: " + String.localizedStringWithFormat("%.2f%@", distanceValue, "m")

    let speedUnit = HKUnit.meterUnit().unitDividedByUnit(HKUnit.secondUnit())
    let speedQuantity = HKQuantity(unit: speedUnit, doubleValue: distance / seconds)
    let speedValue = speedQuantity.doubleValueForUnit(speedUnit)
    averageSpeed.text = "Average Speed: " + String.localizedStringWithFormat("%.2f%@", speedValue, "m/s")
  }

  func startLocationUpdates() {
    locationManager.startUpdatingLocation()
  }

  func saveRun() {
    // 1
    let savedRun = NSEntityDescription.insertNewObjectForEntityForName("Run",
      inManagedObjectContext: managedObjectContext!) as! Run
    savedRun.distance = distance
    savedRun.duration = seconds
    savedRun.timestamp = NSDate()

    // 2
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

    // 3
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
    startButton.hidden = true
    promptMessage.hidden = true
    timeLabel.hidden = false
    distanceLabel.hidden = false
    averageSpeed.hidden = false
    stopButton.hidden = false

    seconds = 0.0
    distance = 0.0
    locations.removeAll(keepCapacity: false)
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
    let actionSheet = UIActionSheet(
        title: "Run Stopped",
        delegate: self,
        cancelButtonTitle: "Cancel",
        destructiveButtonTitle: nil,
        otherButtonTitles: "Save", "Discard")
    actionSheet.actionSheetStyle = .Default
    actionSheet.showInView(view)
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
    renderer.strokeColor = UIColor.blueColor()
    renderer.lineWidth = 3
    return renderer
  }
}

// use this to get update using location manager
extension NewRunViewController: CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    for location in locations {
      let howRecent = location.timestamp.timeIntervalSinceNow
        
        // check to make sure the data is accurate enough and that the data is recent enough
      if abs(howRecent) < 10 && location.horizontalAccuracy < 20 {
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
  }
}

// MARK: - UIActionSheetDelegate
extension NewRunViewController: UIActionSheetDelegate {
  func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
    //save
    if buttonIndex == 1 {
      saveRun()
      performSegueWithIdentifier(DetailSegueName, sender: nil)
    }
      //discard
    else if buttonIndex == 2 {
      navigationController?.popToRootViewControllerAnimated(true)
    }
  }
}
