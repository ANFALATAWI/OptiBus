//
//  ViewController.swift
//  OptiBus
//
//  Created by Anfal Alatawi on 28/09/2018.
//  Copyright © 2018 Anfal Alatawi. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    //Routes:
    let campRoute = [BusStop(name: "Tamimi Stop", location: CLLocationCoordinate2DMake(22.314909, 39.104631),numberOfPassengers: 10, zoom: 15),
                     BusStop(name: "KAUST Health Clinic", location: CLLocationCoordinate2DMake(22.314568, 39.106207), numberOfPassengers: 20, zoom: 17),
                     BusStop(name: "BLDG 16", location: CLLocationCoordinate2DMake(22.309683, 39.104700), numberOfPassengers: 30, zoom: 17),
                     BusStop(name: "BLDG 14", location: CLLocationCoordinate2DMake(22.307897, 39.106464), numberOfPassengers: 40, zoom: 17),
                     BusStop(name: "BLDG 18", location: CLLocationCoordinate2DMake(22.311541, 39.102528),numberOfPassengers: 50, zoom: 17)]
    
    let oRoute = [BusStop(name: "Tamimi Stop", location: CLLocationCoordinate2DMake(22.314909, 39.104631),numberOfPassengers: 10, zoom: 15),
                  BusStop(name: "KAUST Health Clinic", location: CLLocationCoordinate2DMake(22.314568, 39.106207), numberOfPassengers: 20, zoom: 17),
                  BusStop(name: "BLDG 16", location: CLLocationCoordinate2DMake(22.309683, 39.104700), numberOfPassengers: 30, zoom: 17),
                  BusStop(name: "BLDG 14", location: CLLocationCoordinate2DMake(22.307897, 39.106464), numberOfPassengers: 40, zoom: 17),
                  BusStop(name: "BLDG 18", location: CLLocationCoordinate2DMake(22.311541, 39.102528),numberOfPassengers: 50, zoom: 17)]
    
    //Vars:
    var mapView: GMSMapView? = nil
    var destinationBustStop: BusStop?
    var busStops : [BusStop]? = nil
    let label = "camp"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        GMSServices.provideAPIKey("AIzaSyDcJz5qLjIYCZsabCvQf62w9bb92dhDBLA")
        
        //choose stop:
        if label == "camp"{
            busStops = campRoute
        } else {
            busStops = oRoute
        }
        
        //initiall pin
        let camera = GMSCameraPosition.camera(withLatitude: 22.314909, longitude: 39.104631, zoom: 15) //as this increases, you zoom more.
        mapView = GMSMapView.map(withFrame: CGRect.zero , camera: camera)
        view = mapView
        
        let currentLocation = CLLocationCoordinate2DMake( 22.314909,39.104631)
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 22.314909, longitude: 39.104631)
        marker.title = "Stop: Tamimi Markets"
        marker.snippet = "Bus Stop 1"
       // marker.icon = GMSMarker.markerImage(with: ) MARKER COLOR
        marker.map = mapView
        
    }
    
    @IBAction func nextStop(_ sender: UIBarButtonItem) {
        
        //clearing the prev mark.
        mapView?.clear()
        var origin: String?
        
        if destinationBustStop == nil { //if this is the first destination in list:
            destinationBustStop = busStops?.first
            origin = "\(destinationBustStop!.location.latitude),\(destinationBustStop!.location.longitude)"
        }else{
            //take current loc
            origin = "\(destinationBustStop!.location.latitude),\(destinationBustStop!.location.longitude)"
            //give me next stop
            if var index = busStops?.index(of: destinationBustStop!){
                if index == ((busStops?.count)! - 1)
                {
                    destinationBustStop = busStops?[0]
                }else{
                    
                    //get index
                    //JSON:
                    let parameters = ["stopID" : index]
                    //var dest = 4 //: Int?
                    
                    print(parameters) //PRINITING***
                    
                    let url = "http://10.85.86.184:5000/driver"
                    
                    Alamofire.request(url, method: .get, parameters: parameters).responseJSON{
                        response in
                        if response.result.isSuccess{
                            print("Success! Got Data.")
                            
                            let JSONData : JSON = JSON(response.result.value!)
                            print("JSON Data: ")
                            print(JSONData)
                            //handle answer.
                            index = JSONData["stopID"].intValue
                            self.destinationBustStop = self.busStops?[index]
                            
                            //drawing:
                            let destination = "\(self.destinationBustStop!.location.latitude),\(self.destinationBustStop!.location.longitude)"
                            
                            let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin!)&destination=\(destination)&key=AIzaSyAPtgKcThEe0At_8LVl8lAPoTzOHwCWpZs"
                            
                            Alamofire.request(url).responseJSON { response in
                                do {
                                    let json = try? JSON(data: response.data!)
                                    //                    print(json)
                                    print(origin)
                                    print(destination)
                                    //
                                    let routes = json!["routes"].arrayValue
                                    
                                    for route in routes
                                    {
                                        let routeOverviewPolyline = route["overview_polyline"].dictionary
                                        let points = routeOverviewPolyline?["points"]?.stringValue
                                        let path = GMSPath.init(fromEncodedPath: points!)
                                        let polyline = GMSPolyline.init(path: path)
                                        polyline.strokeWidth = 5
                                        polyline.strokeColor = UIColor.black
                                        
                                        polyline.map = self.mapView
                                    }
                                    
                                }  catch{
                                    
                                }      }
                            self.setMapCamera()
                        }
                        else{
                            print("Error \(response.result.error)")
                            
                        }
                    }
                    //main routing here:
                }
            }
        }
        
        
        
    }
    
    private func skipStop(index: Int) -> Int
    {
        //JSON:
        let parameters = ["stopID" : index]
        var dest = 4 //: Int?
        
        print(parameters) //PRINITING***
        
        let url = "http://10.85.86.184:5000/driver"
        
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON{
            response in
            if response.result.isSuccess{
                print("Success! Got Data.")
                
                let JSONData : JSON = JSON(response.result.value!)
                print("JSON Data: ")
                print(JSONData)
                //handle answer.
                dest = JSONData["stopID"].intValue
                
            }
            else{
                print("Error \(response.result.error)")
                
            }
        }
        return dest;
    }
    
    private func setMapCamera() {
        CATransaction.begin()
        CATransaction.setValue(1, forKey: kCATransactionAnimationDuration)
        mapView?.animate(to: GMSCameraPosition.camera(withTarget: destinationBustStop!.location, zoom: destinationBustStop!.zoom))
        CATransaction.commit()
        
        let marker = GMSMarker(position: destinationBustStop!.location)
        marker.title = destinationBustStop?.name
        marker.map = mapView
    }
    
    class BusStop: NSObject {
        /*
         parameters = [“bus location” : getCurrentStop(), “wantedStops” : [1, 4], “isFull” : false]
         */
        
        let name: String
        let location: CLLocationCoordinate2D
        let numberOfPassengers: Int
        let wantedStops = [0]
        let zoom: Float
        
        init(name: String, location: CLLocationCoordinate2D, numberOfPassengers: Int, zoom: Float) {
            self.name = name
            self.location = location
            self.zoom = zoom
            self.numberOfPassengers = numberOfPassengers
        }
        
    }
    
    class Bus: NSObject {
        
        let name: String
        let isFull = false
        let capacity = 30
        let wantedStops = [0]
        
        init(name: String)
        {
            self.name = name
        }
        
    }
    
    
    
    
}

