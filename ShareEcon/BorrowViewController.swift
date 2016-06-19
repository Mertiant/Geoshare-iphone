//
//  BorrowViewController.swift
//  ShareEcon
//
//  Created by Martin L on 6/18/16.
//  Copyright © 2016 Martin L. All rights reserved.
//

import UIKit
import ArcGIS
import CoreLocation
import Foundation


/*
 Why buy when you can borrow?
We made an app that let's people share the tools they aren't using, so others can use them without buying it.
 */

class BorrowViewController: UIViewController, UISearchBarDelegate, AGSMapViewLayerDelegate, AGSRouteTaskDelegate, AGSLayerCalloutDelegate, UIAlertViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: AGSMapView!
    
    // AGS Route variables
    var graphicsLayer:AGSGraphicsLayer!
    var sketchLayer:AGSSketchGraphicsLayer!
    var routeTask:AGSRouteTask!
    var routeTaskParams:AGSRouteTaskParameters!
    var currentStopGraphic:AGSStopGraphic!
    var selectedGraphic:AGSGraphic!
    var currentDirectionGraphic:AGSDirectionGraphic!
    var stopCalloutView:UIView!
    var routeResult:AGSRouteResult!
    
    var  locationManager:CLLocationManager!
    var lat: Double = 70
    var long: Double = -40
    
    let kTiledMapServiceUrl = "http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"
    let kRouteTaskUrl = "http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Network/USA/NAServer/Route"
    
    var numStops:Int = 0
    var numBarriers:Int = 0
    var directionIndex:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()


        // Do any additional setup after loading the view.
         searchBar.delegate = self
        
        // Load a tiled map service
        let mapUrl = NSURL(string: kTiledMapServiceUrl)
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        // zoom to some location (this is San Francisco)

        let sr = AGSSpatialReference.wgs84SpatialReference()
        let env = AGSEnvelope(xmin: long - 5.5,
                              ymin: lat - 5.5,
                              xmax: long + 5.5,
                              ymax: lat + 5.5,
                              spatialReference:sr)
        self.mapView.zoomToEnvelope(env, animated:true)
        
        // Setup the route task
        let routeTaskUrl = NSURL(string: kRouteTaskUrl)
        self.routeTask = AGSRouteTask(URL: routeTaskUrl)
        
        // assign delegate to this view controller
        self.routeTask.delegate = self
        
        
        // kick off asynchronous method to retrieve default parameters
        // for the route task
        self.routeTask.retrieveDefaultRouteTaskParameters()
        
        // add sketch layer to the map
        let mp = AGSMutablePoint(spatialReference: sr)
        self.sketchLayer = AGSSketchGraphicsLayer(geometry: mp)
        self.mapView.addMapLayer(self.sketchLayer, withName:"sketchLayer")
        
        // set the mapView's touchDelegate to the sketchLayer so we get points symbolized when sketching
        self.mapView.touchDelegate = self.sketchLayer
        
        // add graphics layer
        self.graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.graphicsLayer, withName:"Route results")
        
        // set the callout delegate so we can display callouts
        self.graphicsLayer.calloutDelegate = self
        
        // create a custom callout view using a button with an image
        // this is to remove stops after we add them to the map
        let removeStopBtn = UIButton(type: .Custom)
        removeStopBtn.frame = CGRectMake(0, 0, 24, 24)
        removeStopBtn.setImage(UIImage(named: "remove24.png"), forState:.Normal)
        removeStopBtn.addTarget(self, action: "removeStopClicked", forControlEvents: .TouchUpInside)
        self.stopCalloutView = removeStopBtn
        

    }
    @IBOutlet weak var searchBar: UISearchBar!

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        print("searchText \(searchText)")
        addStop()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        print("searchText \(searchBar.text)")
        routeBtnClicked()
    }
    
    


    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        long = locations[0].coordinate.longitude; // x
        lat = locations[0].coordinate.latitude; // y
        
        if numStops == 0{
            print (long, lat)
            let sr = AGSSpatialReference.wgs84SpatialReference()
            let env = AGSEnvelope(xmin: long - 0.1,
                                  ymin: lat - 0.1,
                                  xmax: long + 0.1,
                                  ymax: lat + 0.1,
                                  spatialReference:sr)
            self.mapView.zoomToEnvelope(env, animated:true)
            //Projection
            let geometryEngine = AGSGeometryEngine.defaultGeometryEngine()
            let curLoc = AGSPoint(x: long, y: lat, spatialReference: sr)
            self.sketchLayer.insertVertex(curLoc, inPart: 0, atIndex: -1)
            let geometries = self.sketchLayer.geometry as AGSGeometry
            let newGeometry = geometryEngine.projectGeometry(geometries, toSpatialReference: AGSSpatialReference.webMercatorSpatialReference())
            self.sketchLayer.geometry = newGeometry
            addStop()

        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func mapViewDidLoad(mapView: AGSMapView!) {
        //do something now that the map is loaded
        //for example, show the current location on the map
        mapView.locationDisplay.startDataSource()
    }
    
    //MARK: - AGSRouteTaskDelegate
    
    //
    // we got the default parameters from the service
    //
    func routeTask(routeTask: AGSRouteTask!, operation op: NSOperation!, didRetrieveDefaultRouteTaskParameters routeParams: AGSRouteTaskParameters!) {
        self.routeTaskParams = routeParams
    }
    
    //
    // an error was encountered while getting defaults
    //
    func routeTask(routeTask: AGSRouteTask!, operation op: NSOperation!, didFailToRetrieveDefaultRouteTaskParametersWithError error: NSError!) {
        // Create an alert to let the user know the retrieval failed
        // Click Retry to attempt to retrieve the defaults again
        UIAlertView(title: "Error", message: "Failed to retrieve default route parameters", delegate: self, cancelButtonTitle: "Ok").show()
    }
    
    
    
    
    //
    // route was solved
    //
    func routeTask(routeTask: AGSRouteTask!, operation op: NSOperation!, didSolveWithResult routeTaskResult: AGSRouteTaskResult!) {
    
        // we know that we are only dealing with 1 route...
        self.routeResult = routeTaskResult.routeResults.last as! AGSRouteResult
        if self.routeResult != nil {
            // symbolize the returned route graphic
            self.routeResult.routeGraphic.symbol = self.routeSymbol()
            
            // add the route graphic to the graphic's layer
            self.graphicsLayer.addGraphic(self.routeResult.routeGraphic)
            
            // enable the next button so the user can traverse directions
            //self.nextBtn.enabled = true
            
            // remove the stop graphics from the graphics layer
            // careful not to attempt to mutate the graphics array while
            // it is being enumerated
            //TODO: test this functionality
            let graphics = self.graphicsLayer.graphics
            for g in graphics {
                if g is AGSStopGraphic {
                    self.graphicsLayer.removeGraphic(g as! AGSStopGraphic)
                }
            }
            
            // add the returned stops...it's possible these came back in a different order
            // because we specified findBestSequence
            for sg in self.routeResult.stopGraphics as! [AGSStopGraphic] {
                
                // get the sequence from the attribetus
                var exists:ObjCBool = false
                let sequence = sg.attributeAsIntegerForKey("Sequence", exists: &exists)
                
                // create a composite symbol using the sequence number
                sg.symbol = self.stopSymbolWithNumber(sequence)
                
                // add the graphic
                self.graphicsLayer.addGraphic(sg)
            }
        }
    }
    
    //
    // solve failed
    //
    func routeTask(routeTask: AGSRouteTask!, operation op: NSOperation!, didFailSolveWithError error: NSError!) {
        // the solve route failed...
        // let the user know
        UIAlertView(title: "Solve Route Failed", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
        print("Solve Route Failed :: \(error)")
    }


    //
    // create our route symbol
    //
    func routeSymbol() -> AGSCompositeSymbol {
        let cs = AGSCompositeSymbol()
        
        let sls1 = AGSSimpleLineSymbol()
        sls1.color = UIColor.yellowColor()
        sls1.style = .Solid
        sls1.width = 8
        cs.addSymbol(sls1)
        
        let sls2 = AGSSimpleLineSymbol()
        sls2.color = UIColor.blueColor()
        sls2.style = .Solid
        sls2.width = 4
        cs.addSymbol(sls2)
        
        return cs
    }
    
    
    //
    // create a composite symbol with a number
    //
    func stopSymbolWithNumber(stopNumber:Int) -> AGSCompositeSymbol {
        let cs = AGSCompositeSymbol()
        
        // create outline
        let sls = AGSSimpleLineSymbol()
        sls.color = UIColor.blackColor()
        sls.width = 2
        sls.style = .Solid
        
        // create main circle
        let sms = AGSSimpleMarkerSymbol()
        sms.color = UIColor.greenColor()
        sms.outline = sls
        sms.size = CGSizeMake(20, 20)
        sms.style = .Circle
        cs.addSymbol(sms)
        
        //    // add number as a text symbol
        let ts = AGSTextSymbol(text: "\(stopNumber)", color: UIColor.blackColor())
        ts.vAlignment = .Middle
        ts.hAlignment = .Center
        ts.fontSize	= 16
        cs.addSymbol(ts)
        
        return cs
    }
    
    //MARK: - AGSLayerCalloutDelegate
    
    func callout(callout: AGSCallout!, willShowForFeature feature: AGSFeature!, layer: AGSLayer!, mapPoint: AGSPoint!) -> Bool {
        let graphic = feature as! AGSGraphic
        
        let stopNum = graphic.attributeAsStringForKey("stopNumber")
        let barrierNum = graphic.attributeAsStringForKey("barrierNumber")
        
        if stopNum != nil || barrierNum != nil {
            self.selectedGraphic = graphic
            self.mapView.callout.customView = self.stopCalloutView
            self.sketchLayer.clear()
            return true
        }else{
            return false
        }
    }
    
    
    func addStop() {
    
        //grab the geometry, then clear the sketch
        //TODO: check for copy
    
        
        let geometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        print(geometry)
        self.sketchLayer.clear()
        
        //Prepare symbol and attributes for the Stop/Barrier
        var attributes = [String: Int]()
        var symbol:AGSSymbol!
        
        //Stop
        self.numStops++
        print(self.numStops)
        attributes["stopNumber"] = self.numStops
        symbol = self.stopSymbolWithNumber(self.numStops)
        let stopGraphic = AGSStopGraphic(geometry: geometry, symbol:symbol, attributes:attributes)
        stopGraphic.sequence = UInt(self.numStops)
        
        //You can set additional properties on the stop here
        //refer to the conceptual helf for Routing task
        self.graphicsLayer.addGraphic(stopGraphic)
        
        let g = AGSGraphic(geometry: geometry, symbol: symbol, attributes: attributes)
        self.graphicsLayer.addGraphic(g)

    }
    
    //
    // perform the route task's solve operation
    //
    func routeBtnClicked() {
        
        // if we have a sketch layer on the map, remove it
        if (self.mapView.mapLayers as! [AGSLayer]).contains(self.sketchLayer) {
            self.mapView.removeMapLayerWithName(self.sketchLayer.name)
            self.mapView.touchDelegate = nil
            self.sketchLayer = nil
        }
        
        var stops = [AGSStopGraphic]()
        
        // get the stop, barriers for the route task
        for g in self.graphicsLayer.graphics {
            // if it's a stop graphic, add the object to stops
            if g is AGSStopGraphic {
                stops.append(g as! AGSStopGraphic)
                
            }
        }
        
        // set the stop and polygon barriers on the parameters object
        if (stops.count > 0) {
            self.routeTaskParams.setStopsWithFeatures(stops)
        }
        
        
        // this generalizes the route graphics that are returned
        self.routeTaskParams.outputGeometryPrecision = 5.0
        self.routeTaskParams.outputGeometryPrecisionUnits = .Meters
        
        // return the graphic representing the entire route, generalized by the previous
        // 2 properties: outputGeometryPrecision and outputGeometryPrecisionUnits
        self.routeTaskParams.returnRouteGraphics = true
        
        // this returns turn-by-turn directions
        self.routeTaskParams.returnDirections = true
        
        // the next 3 lines will cause the task to find the
        // best route regardless of the stop input order
        self.routeTaskParams.findBestSequence = true
        self.routeTaskParams.preserveFirstStop = true
        self.routeTaskParams.preserveLastStop = false
        
        // since we used "findBestSequence" we need to
        // get the newly reordered stops
        self.routeTaskParams.returnStopGraphics = true
        
        // ensure the graphics are returned in our map's spatial reference
        self.routeTaskParams.outSpatialReference = self.mapView.spatialReference;
        
        // let's ignore invalid locations
        self.routeTaskParams.ignoreInvalidLocations = true
        
        // you can also set additional properties here that should
        // be considered during analysis.
        // See the conceptual help for Routing task.
        
        // execute the route task
        self.routeTask.solveWithParameters(self.routeTaskParams)
    }

    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
