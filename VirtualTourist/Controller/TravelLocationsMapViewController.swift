//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Mohamed Metwaly on 2019-05-20.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var pins:[Pin] = []
    var annotations = [MKPointAnnotation]()
    var dataController:DataController!
    var photos = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let tap = UILongPressGestureRecognizer(target: self, action: #selector(self.addAnnotation(_:)))
        tap.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(tap)
        
        setupMapView()
        fetchPinAnnotations()
    }
    /*https://stackoverflow.com/questions/3959994/how-to-add-a-push-pin-to-a-mkmapviewios-when-touching/3960754#3960754*/
    
    @objc func addAnnotation (_ sender: UITapGestureRecognizer) {
        if sender.state != .began {
            return
        }
        let touchPoint:CGPoint = sender.location(in: mapView)
        let touchMapCoordinate:CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annonation = MKPointAnnotation()
        annonation.coordinate = touchMapCoordinate
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = annonation.coordinate.latitude
        pin.longitude = annonation.coordinate.longitude
        //TODO: add error handling
        try? dataController.viewContext.save()
        
        mapView.addAnnotation(annonation)
        
    }
    
    //MARK: Helper methods
    func setupMapView(){
        if UserDefaults.standard.bool(forKey: "centerLatitude") {
            let center:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: UserDefaults.standard.value(forKey: "centerLatitude") as! CLLocationDegrees, longitude: UserDefaults.standard.value(forKey: "centerLongitude") as! CLLocationDegrees)
            var region:MKCoordinateRegion = MKCoordinateRegion()
            region.center = center
            region.span.longitudeDelta = UserDefaults.standard.value(forKey: "spanLongitude") as! CLLocationDegrees
            region.span.latitudeDelta = UserDefaults.standard.value(forKey: "spanLatitude") as! CLLocationDegrees
            mapView.setRegion(region, animated: true)
        }
    }
    
    func fetchPinAnnotations() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            pins = result
        }
        
        for pin in pins {
            let point:MKPointAnnotation = MKPointAnnotation()
            point.coordinate.latitude = pin.latitude
            point.coordinate.longitude = pin.longitude
            annotations.append(point)
        }
        mapView.addAnnotations(annotations)
    }
    
    func fetchPin(latitude:Double,longitude:Double) -> Pin? {
        var pin:Pin?
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let predicate = NSPredicate(format: "(latitude = %@) AND (longitude = %@)", argumentArray: [latitude,longitude])
        fetchRequest.predicate = predicate
        
        do {
            let result = try dataController.viewContext.fetch(fetchRequest)
            pin = result[0]
        }
        catch {
            //ERROR handling
        }
        return pin
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoAlbum" {
            print("test")
        }
    }
    
}

//MARK: MKMapViewDelegate extension
extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

        UserDefaults.standard.set(mapView.centerCoordinate.latitude , forKey: "centerLatitude")
        UserDefaults.standard.set(mapView.centerCoordinate.longitude , forKey: "centerLongitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta , forKey: "spanLatitude")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta , forKey: "spanLongitude")
        UserDefaults.standard.synchronize()
    }
        
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        vc.pin = view.annotation
        vc.pinCoreData = fetchPin(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        vc.dataController = dataController
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

