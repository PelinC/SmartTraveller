//
//  ViewController.swift
//  TravelBook
//
//  Created by Pelinsu Celebi on 18.08.2020.
//  Copyright © 2020 Pelinsu Celebi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var selectedTitle = ""
    var selectedTitleID : UUID?

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    
    
    var locationManager = CLLocationManager() // get user location
    
    var chosenLat = Double()
    var chosenLong = Double()
    
    
    
    var annotationTitle = ""
    var annotationComment = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // how accurate should the user location must be
        
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.startUpdatingLocation()
        
        
        
        //Recognizer
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        
        mapView.addGestureRecognizer(gestureRecognizer) // add to map view
        
        
        if selectedTitle != "" {
            
            //coreData
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let idString = selectedTitleID!.uuidString
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            
            request.predicate = NSPredicate(format:"id = %@", idString)
            request.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(request)
                
                if results.count>0 {
                    
                    for result in results as! [NSManagedObject] {
                        
                        if let title = result.value(forKey: "name") as? String {
                            
                            annotationTitle = title
                            if let comment = result.value(forKey: "comment") as? String {
                                
                                annotationComment = comment
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        
                                        annotation.subtitle = annotationComment
                                        
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        
                                        nameText.text = annotationTitle
                                        commentText.text = annotationComment
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        
                                        mapView.setRegion(region, animated: true)
                                        
                                        
                                        
                                    }
                                }
                                
                            }
                            
                            
                            
                        }
                        
                    }
                    
                }
                
                
            } catch{
                
                print("Error")
            }
            
        }
    }
    
    
    //Save Button
    @IBAction func saveButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameText.text, forKey: "name")
        newPlace.setValue(commentText.text, forKey: "comment")
        newPlace.setValue(chosenLat, forKey: "Latitude")
        newPlace.setValue(chosenLong, forKey: "Longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        do{
            
            try context.save()
        } catch {
            
            print("Error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"),object: nil) //notify app and add observer in the other controller to act upon notification
        
        navigationController?.popViewController(animated: true)
        
        
        
    }
    
  
    
    //Selector Function
    
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            
            chosenLat = touchedCoordinates.latitude
            chosenLong = touchedCoordinates.longitude
            
            //Add Pin
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
    }
   
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if selectedTitle == ""{
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) //user location
        
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) //zoom level
        
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        }

    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                //closure
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                                      
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                                      
                }
            }
        }
            
            
        }
    
    
    
    
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        
        
        return pinView
    }


}

