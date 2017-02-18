//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Flavio Kreis on 17/02/17.
//  Copyright © 2017 Flavio Kreis. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    var stack: CoreDataStack?
    var managedObjectContext:NSManagedObjectContext?
    var pinFetchRequest:NSFetchRequest<NSFetchRequestResult>?
    var urls = [URL]()
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        pinFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        managedObjectContext = stack?.context
        
        addGestureRecognizer()
        
        addAllPins()
    }
    
    func addGestureRecognizer() {
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(self.addPin(gestureRecognizer:)))
        longPressGR.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGR)
    }
    
    func fetchAllPins() -> [Pin] {
        var pins = [Pin]()
        do {
            pins = try managedObjectContext!.fetch(pinFetchRequest!) as! [Pin]
        } catch let e as NSError {
            print(e)
        }
        return pins
    }
    
    func addAllPins() {
        let pins:[Pin] = fetchAllPins()
        for pin in pins {
            let annotation = MKPointAnnotation()
            let coordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            annotation.coordinate = coordinates
            mapView.addAnnotation(annotation)
        }
    }
    
    func fetchPin(lat:Double, lon:Double) -> Pin {
        let predicate = NSPredicate(format: "latitude == %lf AND longitude == %lf", lat, lon)
        pinFetchRequest!.predicate = predicate
        var place = [Pin]()
        do {
            place = try managedObjectContext!.fetch(pinFetchRequest!) as! [Pin]
        } catch let e as NSError {
            print(e)
        }
        return place[0]
    }
    
    func addPin(gestureRecognizer: UILongPressGestureRecognizer) {
        
        guard gestureRecognizer.state == .began else {
            return
        }
        
        let coordinates = mapView.convert(gestureRecognizer.location(in: mapView), toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        mapView.addAnnotation(annotation)
        
        _ = Pin(latitude: coordinates.latitude as Double, longitude: coordinates.longitude as Double, context: (stack?.context)!)
        stack?.save()
        
        FlickrClient.shared.getPhotos(latitude: coordinates.latitude as Double, longitude: coordinates.longitude as Double, page: 1) { (success, data, error) in

            guard let photos = data?[FlickrClient.JSONResponseKeys.Photo] as? [[String:AnyObject]] else {
                return
            }
            
            for photo in photos {
                self.urls.append(FlickrClient.createPhotoUrl(photo))
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "showPinSegue" {
            let destination = segue.destination as! PinPhotoCollectionViewController
            let lat = mapView.selectedAnnotations.first?.coordinate.latitude
            let lon = mapView.selectedAnnotations.first?.coordinate.longitude
            let pin = fetchPin(lat: lat!, lon: lon!)
            destination.pin = pin
            destination.urls = urls
            urls.removeAll()
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
            pinView?.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.performSegue(withIdentifier: "showPinSegue", sender: self)
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
}

