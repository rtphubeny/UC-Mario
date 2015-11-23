import UIKit
import MapKit
import HealthKit

class DetailViewController: UIViewController {
  var run: Run!

  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var coinsLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var distanceLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
    /*if (run.coins == 15){
        sendScore()
    }*/
  }

  func configureView() {
    // let coinsQuantity = run.coins.doubleValue
    coinsLabel.text = "Coins Collected -  0/15"

    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = .MediumStyle
    dateLabel.text = dateFormatter.stringFromDate(run.timestamp)

    let secondsQuantity = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: run.duration.doubleValue)
    timeLabel.text = "Time - " + secondsQuantity.description

    let distanceQuantity = HKQuantity(unit: HKUnit.meterUnit(), doubleValue: run.distance.doubleValue)
    let distanceValue = distanceQuantity.doubleValueForUnit(HKUnit.meterUnit())
    distanceLabel.text = "Distance Traveled- " + String.localizedStringWithFormat("%.2f%@", distanceValue, "m")

    loadMap()
  }

  func mapRegion() -> MKCoordinateRegion {
    let initialLoc = run.locations.firstObject as! Location

    var minLat = initialLoc.latitude.doubleValue
    var minLng = initialLoc.longitude.doubleValue
    var maxLat = minLat
    var maxLng = minLng

    let locations = run.locations.array as! [Location]

    for location in locations {
      minLat = min(minLat, location.latitude.doubleValue)
      minLng = min(minLng, location.longitude.doubleValue)
      maxLat = max(maxLat, location.latitude.doubleValue)
      maxLng = max(maxLng, location.longitude.doubleValue)
    }

    return MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: (minLat + maxLat)/2,
        longitude: (minLng + maxLng)/2),
      span: MKCoordinateSpan(latitudeDelta: (maxLat - minLat)*1.1,
        longitudeDelta: (maxLng - minLng)*1.1))
  }

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

  func polyline() -> MKPolyline {
    var coords = [CLLocationCoordinate2D]()

    let locations = run.locations.array as! [Location]
    for location in locations {
      coords.append(CLLocationCoordinate2D(latitude: location.latitude.doubleValue,
        longitude: location.longitude.doubleValue))
    }

    return MKPolyline(coordinates: &coords, count: run.locations.count)
  }

  func loadMap() {
    if run.locations.count > 0 {
        mapView.hidden = false
        
        // Set the map bounds
        mapView.region = mapRegion()
        
        // Make the line(s!) on the map
        mapView.addOverlay(polyline())
    } else {
      // No locations were found!
      mapView.hidden = true

      UIAlertView(title: "Error",
        message: "Sorry, this run has no locations saved",
        delegate:nil,
        cancelButtonTitle: "OK").show()
    }
  }
    func sendScore() {
        let request = NSMutableURLRequest(URL: NSURL(string: "http://www.ucmario.eu.pn")!)
        request.HTTPMethod = "POST"
        let postString = "score=" + String(run.duration)
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                print("error=\(error)")
                return
            }
        }
        task!.resume()
    }

}

// MARK: - MKMapViewDelegate
extension DetailViewController: MKMapViewDelegate {
}
