//
//  ViewController.swift
//  bikeshare
//
//  Created by houlianglv on 4/12/16.
//  Copyright © 2016 team O. All rights reserved.
//

import UIKit
import GoogleMaps

var serverDomain = "http://209.2.234.154:5000"

class ViewController: UIViewController, UITabBarDelegate,
    GMSMapViewDelegate {

    //outlets
    @IBOutlet weak var gmsMapView: GMSMapView!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var fromDateLabel: UILabel!
    @IBOutlet weak var toDateLabel: UILabel!



    var placesClient: GMSPlacesClient?
    var locationManager: CLLocationManager?
    var currentLocation: CLLocationCoordinate2D?
    var filterMarker: GMSMarker?
    var bikesMarker: [Int:GMSMarker]?
    var searchParams: SearchParams?
    var bid: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        //tabBar delegate
        tabBar.delegate = self
        gmsMapView.delegate = self
        self.searchParams = SearchParams(lat: 0, lon: 0, distance: 15,
                                         from: NSDate(), to: NSDate().dateByAddingTimeInterval(21600))
        self.fromDateLabel.text = self.processDateToString(NSDate())
        self.toDateLabel.text = self.processDateToString(NSDate().dateByAddingTimeInterval(21600))
        googleMapSettings()
        getCurrentLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let vc = segue.destinationViewController as? FilterViewController{
            vc.onDataAvailable = { [weak self]
                (data) in
                if let weakSelf = self {
                    weakSelf.processStartAndEndDate(data)
                }
            }
        }else if let vc = segue.destinationViewController as? BikeInfoViewController{
            vc.bid = self.bid
            vc.fromDate = self.searchParams?.from_date
            vc.toDate = self.searchParams?.to_date
        }
    }

    private func processStartAndEndDate(data: String){
        let dates = data.componentsSeparatedByString("*")
        if var params = self.searchParams{
            let RFC3339DateFormatter = NSDateFormatter()
            RFC3339DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            RFC3339DateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: -14400)
            params.from_date = RFC3339DateFormatter.dateFromString(dates[0])!
            params.to_date = RFC3339DateFormatter.dateFromString(dates[1])!
            self.fromDateLabel.text = self.processDateToString(params.from_date)
            self.toDateLabel.text = self.processDateToString(params.to_date)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        let prefs:NSUserDefaults = NSUserDefaults.standardUserDefaults()
        let isLoggedIn:Bool = prefs.boolForKey("ISLOGGEDIN") as Bool
        if (!isLoggedIn) {
            self.performSegueWithIdentifier("goto_login", sender: self)
        } else {
            self.renderBikesByMarkerLocation()
        }

    }

    private func googleMapSettings(){

        placesClient = GMSPlacesClient()
        locationManager = CLLocationManager()

        locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestAlwaysAuthorization()

        gmsMapView.myLocationEnabled = true
        gmsMapView.settings.myLocationButton = true
        
    }

    private func getCurrentLocation(){
        //get current place callback
        placesClient?.currentPlaceWithCallback({
            (placeLikelihoodList: GMSPlaceLikelihoodList?, error: NSError?) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }

            if let placeLicklihoodList = placeLikelihoodList {
                let place = placeLicklihoodList.likelihoods.first?.place
                if let place = place {


                    //this is a async callback so we need to render bikes in this block
                    self.currentLocation = place.coordinate
                    // Do any additional setup after loading the view, typically from a nib.
                    let camera = GMSCameraPosition.cameraWithTarget(place.coordinate, zoom: 16)
                    self.gmsMapView.camera = camera
                    self.showFilterMarker(place.coordinate)
                    self.renderBikesByMarkerLocation()
                }


            }
        })
    }

    private func showFilterMarker(location: CLLocationCoordinate2D){
        if let filterMarker = self.filterMarker{
            //remove the previous marker
            filterMarker.map = nil
        }

        let marker = GMSMarker()
        marker.position = location
        marker.draggable = true
        marker.tappable = false
        marker.map = gmsMapView
        self.filterMarker = marker
        self.searchParams!.lat = marker.position.latitude
        self.searchParams!.lon = marker.position.longitude

    }

    private func renderBikesByMarkerLocation(){

        print(self.searchParams)

        let RFC3339DateFormatter = NSDateFormatter()
        RFC3339DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: -14400)

        let fromDate = RFC3339DateFormatter.stringFromDate(self.searchParams!.from_date)
        let toDate = RFC3339DateFormatter.stringFromDate(self.searchParams!.to_date)

        let query = "lat=\(self.searchParams!.lat)&lon=\(self.searchParams!.lon)&distance=15.0&from_date=" + fromDate
            + "&to_date=" + toDate
        let urlstring = serverDomain + "/getAvailableBikes?" + query
        let url = NSURL(string: urlstring.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
        print(url)

        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in

            if let httpResponse = response as? NSHTTPURLResponse {
                if(httpResponse.statusCode == 403){
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self.performSegueWithIdentifier("goto_login", sender: self)
                    }
                    return
                }
            } else {
                assertionFailure("unexpected response")
            }

            if let bikes = data{
                print(NSString(data: bikes, encoding: NSUTF8StringEncoding))

                do {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(bikes, options: .AllowFragments)
                    var bikesCoordinates = [Int: [Double]]()

                    for anItem in jsonResult["result"] as! [Dictionary<String, AnyObject>] {
                        let coordinates = anItem["geometry"]!["coordinates"] as! [Double]
                        let bid = anItem["properties"]!["bid"] as! Int
                        print(bid)
                        print(coordinates)
                        bikesCoordinates[bid] = coordinates
                    }

                    self.renderBikesMarkers(bikesCoordinates)

                } catch {
                    print("error serializing JSON: \(error)")
                }
            }
        }
        task.resume()
    }

    private func renderBikesMarkers(markersCoordinates: [Int:[Double]]){
        if let bikesMarker = self.bikesMarker {
            //remove the previous marker
            for (_, marker) in bikesMarker{
                marker.map = nil
            }
        }else{
            self.bikesMarker = [Int: GMSMarker]()
        }

        self.bikesMarker?.removeAll()

        for (bid, markerCoordinates) in markersCoordinates{
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: markerCoordinates[0], longitude: markerCoordinates[1])
            marker.draggable = false
            marker.tappable = true
            marker.map = gmsMapView
            marker.icon = GMSMarker.markerImageWithColor(UIColor.blueColor())
            marker.userData = bid
            self.bikesMarker![bid] = marker
        }
    }


    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        let index = Int((self.tabBar.items?.indexOf(item))!)
        switch index {
        case 0:
            self.performSegueWithIdentifier("goto_dashboard", sender: self)
        case 1:
            self.performSegueWithIdentifier("goto_messages", sender: self)
        case 2:
            self.performSegueWithIdentifier("goto_bikes", sender: self)
        case 3:
            self.performSegueWithIdentifier("goto_profile", sender: self)
        default:
            return
        }

    }

    private func processDateToString(date: NSDate) -> String{
        let RFC3339DateFormatter = NSDateFormatter()
        RFC3339DateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        RFC3339DateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: -14400)

        return RFC3339DateFormatter.stringFromDate(date)
    }

    //actions
    


    // GMSMapViewDelegate delegate
    func didTapMyLocationButtonForMapView(mapView: GMSMapView) -> Bool {
        // reset marker:
        showFilterMarker(self.gmsMapView.myLocation!.coordinate)
        self.renderBikesByMarkerLocation()
        return false
    }

    func mapView(mapView: GMSMapView, didEndDraggingMarker marker: GMSMarker) {
        //called after dragging marker ends.
        self.searchParams!.lat = self.filterMarker!.position.latitude
        self.searchParams!.lon = self.filterMarker!.position.longitude
        self.renderBikesByMarkerLocation()
    }

    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        self.bid = marker.userData as? Int
        self.performSegueWithIdentifier("goto_bikedetail", sender: self)
        return false
    }



}

public struct SearchParams{

    /** coordinate */
    public var lat: Double
    public var lon: Double
    /** distance */
    public var distance: Float

    /** From date */
    public var from_date: NSDate
    /** To date */
    public var to_date: NSDate
    public init(lat: Double, lon: Double, distance: Float, from: NSDate, to: NSDate){
        self.lat = lat
        self.lon = lon
        self.distance = distance
        self.from_date = from
        self.to_date = to
    }
}
