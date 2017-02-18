//
//  PinPhotoCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Flavio Kreis on 18/02/17.
//  Copyright © 2017 Flavio Kreis. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class PinPhotoCollectionViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var leftBarButton: UIBarButtonItem!
    @IBOutlet weak var bottomBarButton: UIButton!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    let reuseIdentifier = "PhotoCollectionCell"
    
    var stack: CoreDataStack?
    var managedObjectContext:NSManagedObjectContext?
    var photoFetchRequest:NSFetchRequest<NSFetchRequestResult>?
    
    var photos:[Photo?] = []
    let itemPerRow: CGFloat = 3
    let sectionInsects = UIEdgeInsets(top: 0.0, left: 3.0, bottom: 0.0, right: 3.0)
    var pageNumber = 1
    
    var pin: Pin?
    var urls: [URL]?

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        
        noImagesLabel.isHidden = true
        
        photoFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        stack = delegate.stack
        managedObjectContext = stack?.context
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let pin = pin {
            let annotation = MKPointAnnotation()
            let coordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            annotation.coordinate = coordinates
            
            var region: MKCoordinateRegion = self.mapView.region;
            region.center = coordinates;
            region.span.longitudeDelta *= 0.008;
            region.span.latitudeDelta *= 0.008;
            self.mapView.setRegion(region, animated: true);
            
            mapView.addAnnotation(annotation)
            
            self.syncData()
        }
    }

    @IBAction func selectPhotos(_ sender: Any) {
        if leftBarButton.title == "Select" {
            // Allow Section and sync the
            collectionView.allowsSelection = true
            collectionView.allowsMultipleSelection = true
            leftBarButton.title = "Cancel"
            bottomBarButton.titleLabel?.text = "Remove Selected"
            syncData()
        } else {
            collectionView.allowsSelection = false
            leftBarButton.title = "Select"
            bottomBarButton.titleLabel?.text = "Download New Collection"
            syncData()
        }
    }
    
    @IBAction func bottomButton(_ sender: Any) {
        if bottomBarButton.titleLabel?.text == "Download New Collection" {
            
            bottomBarButton.isEnabled = false
            for cell in collectionView.visibleCells as! [PhotoCollectionViewCell] {
                cell.imageView.image = nil
            }
            for photo in photos {
                self.stack?.context.delete(photo!)
            }
            self.stack?.save()
            urls?.removeAll()
            syncData()
            pageNumber = pageNumber + 1
            FlickrClient.shared.getPhotos(latitude: (pin?.latitude)! as Double, longitude: (pin?.longitude)! as Double, page: pageNumber) { (success, data, error) in
                
                guard let photos = data?["photo"] as? [[String:AnyObject]] else{
                    return
                }
                
                for photo in photos {
                    self.urls?.append(FlickrClient.createPhotoUrl(photo))
                }
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.bottomBarButton.isEnabled = true
                }
            }
            
        }
        
        if bottomBarButton.titleLabel?.text == "Remove Selected" {
            
            for item in collectionView.indexPathsForSelectedItems! {
                
                if let photo = photos[item.row] {
                    self.stack!.context.delete(photo)
                }
                self.stack?.save()
            }
            syncData()
        }
    }
    
    
    func syncData() {
        fetchPhotos()
        collectionView.reloadData()
    }
    
    func fetchPhotos() {
        
        var photos = [Photo]()
        if let pin = pin {
            let predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
            photoFetchRequest!.predicate = predicate
            
            do {
                photos = try stack!.context.fetch(photoFetchRequest!) as! [Photo]
            } catch let e as NSError {
                print(e)
            }
        }
        self.photos = photos
    }

}

extension PinPhotoCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let value = photos.isEmpty ? (urls?.count)! : photos.count
        
        noImagesLabel.isHidden = value != 0
        
        return value
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        
        // If Photo Instance is not exist in CoreData
        guard photos.indices.contains(indexPath.row) else {
            let url = urls?[indexPath.row]
            
            FlickrClient.shared.downloadPhoto(url: url!) { (data, response, error) in
                
                guard let data = data else {
                    print(response!)
                    print(error!)
                    return
                }
                DispatchQueue.main.async {
                    cell.imageView.image = UIImage(data: data)
                    cell.indicatorView.isHidden = true
                    cell.indicatorView.stopAnimating()
                }
                let photo = Photo(data: data, context: (self.stack?.context)!)
                photo.pin = self.pin
                self.stack?.save()
                self.fetchPhotos()
            }
            cell.indicatorView.isHidden = false
            cell.indicatorView.startAnimating()
            cell.removeIndicator.isHidden = true
            return cell
        }
        
        // If Photo Instance is exist in CoreData
        cell.imageView.image = UIImage(data: (photos[indexPath.row]?.image)!)
        cell.removeIndicator.isHidden = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        
        // Show checkbox
        cell.removeIndicator.isHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        
        // Hide Checkbox
        cell.removeIndicator.isHidden = true
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsects.left * (itemPerRow)
        let availableWidth = collectionView.frame.width - paddingSpace
        let widthPerItem = (availableWidth / itemPerRow)
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsects
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsects.left
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension PinPhotoCollectionViewController: MKMapViewDelegate {
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
}
