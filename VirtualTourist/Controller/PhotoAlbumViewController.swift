//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Mohamed Metwaly on 2019-05-22.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController , NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noPhotosLabel: UILabel!
    
    var dataController:DataController!
    var pin:MKAnnotation!
    var pinCoreData: Pin!
    var photosURL:[String]!
    var savedPhotos:[Photo]!
    var photoFetchedResultsController:NSFetchedResultsController<Photo>?
    var photosFetchedResultsController:NSFetchedResultsController<Photo>?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if pinCoreData.photos?.count == 0 {
            loadPictures(page: 1)
        }
        else {
            let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
            savedPhotos = pinCoreData.photos?.sortedArray(using: [sortDescriptor]) as? [Photo]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        newCollectionButton.isEnabled = false
        noPhotosLabel.isHidden = true
        setupMapView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        try! dataController.viewContext.save()
        photoFetchedResultsController = nil
        photosFetchedResultsController = nil
    }
    
    @IBAction func getNewPhotos(_ sender: Any) {
        let pages = Int(pinCoreData!.imagePages)
        if pages > 1 {
            if savedPhotos != nil {
                for photo in savedPhotos {
                    dataController.viewContext.delete(photo)
                }
                savedPhotos = []
            }
            else if photosURL != nil {
                for url in photosURL {
                    let photo = fetchPhoto(url:url)
                    dataController.viewContext.delete(photo!)
                }
                photosURL = []
            }
            
            loadPictures(page: Int.random(in: 1...Int(pages)))
            try! dataController.viewContext.save()
        }
    }
    
    func setupMapView() {
        let coordinates = CLLocationCoordinate2D(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
        mapView.addAnnotation(pin)
        mapView.setCenter(coordinates, animated: true)
        let viewRegion = MKCoordinateRegion(center: coordinates, latitudinalMeters: 100000, longitudinalMeters: 100000);
        let adjustedRegion = self.mapView.regionThatFits(viewRegion)
        mapView.setRegion(adjustedRegion, animated: true)
        mapView.isUserInteractionEnabled = false
    }

    func photoObjectToImage(photo:Photo) -> UIImage {
        return UIImage(data: photo.imageData!)!
    }
    
    func getPhotoData(string: String , completion: @escaping (Data)->Void) {
        let url = URL(string: string)
        var data = Data()
        DispatchQueue.global(qos: .background).async {
            do {
                data = try Data(contentsOf: url!)
                completion(data)
            }
            catch {
                print(error)
            }
        }
    }
    
    func setupEmptyAlbum(){
        newCollectionButton.isEnabled = true
    }

    func fetchPhoto(url:String)->Photo? {
        var photo:Photo?
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        let predicate = NSPredicate(format: "url = %@", argumentArray: [url])

        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        
        photoFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        photoFetchedResultsController?.delegate = self
        
        do {
            try photoFetchedResultsController?.performFetch()
            if let result = photoFetchedResultsController?.fetchedObjects {
                photo = result[0]
            }
        }
        catch {
            print(error)
        }
        return photo
    }
    
    //download picture URLs from Flickr
    func loadPictures(page:Int){
        let pages = Int(pinCoreData!.imagePages)
        var page = 1
        if pages > 1 {
            page = Int.random(in: 1...pages)
        }
        newCollectionButton.isEnabled = false
        APIHelper.getPhotos(lat: pin.coordinate.latitude, lon: pin.coordinate.longitude,page: page) { (results, response, pages, error)  in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let results = results else {
                DispatchQueue.main.async {
                    self.noPhotosLabel.isHidden = false
                    self.collectionView.isHidden = true
                }
                return
            }
            if results.count < 1 {
                DispatchQueue.main.async {
                    self.pinCoreData.imagePages = 0
                    self.noPhotosLabel.isHidden = false
                    self.collectionView.isHidden = true
                }
                return
            }
            self.photosURL = results
            
            DispatchQueue.main.async {
                if pages < 2 {
                    self.newCollectionButton.isEnabled = false
                }
                self.pinCoreData.imagePages = Int64(pages)
                for result in results {
                    let photo = Photo(context: self.dataController.viewContext)
                    photo.pin = self.pinCoreData
                    photo.url = result
                }
                self.collectionView.reloadData()
                try! self.dataController.viewContext.save()
                self.newCollectionButton.isEnabled = true
            }
        }
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}

extension PhotoAlbumViewController:UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {

    //MARK: UICollectionViewDataSource methods
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        cell.imageView.image = UIImage(named: "VirtualTourist_76")
        if photosURL != nil {
            let url = URL(string: photosURL[indexPath.row])!
            let photo = self.fetchPhoto(url: self.photosURL[indexPath.row])
            if let data = photo?.imageData {
                cell.imageView.image = UIImage(data: data)
            }
            else {
                DispatchQueue.global(qos: .background).async {
                    do {
                        let data = try Data(contentsOf: url)
                        DispatchQueue.main.async {
                            cell.imageView.image = UIImage(data: data)
                            photo?.imageData = cell.imageView.image?.jpegData(compressionQuality: 1)
                        }
                    }
                    catch {
                        print("error for \(indexPath.row)")
                    }
                }
            }
        }
        else if savedPhotos != nil {
            if let data = savedPhotos[indexPath.row].imageData {
                DispatchQueue.main.async {
                    cell.imageView.image = UIImage(data: data)
                }
            }
            else {
                getPhotoData(string: savedPhotos![indexPath.row].url!) { (data) in
                    DispatchQueue.main.async {
                        self.savedPhotos[indexPath.row].imageData = data
                        cell.imageView.image = UIImage(data: data)
                        try! self.dataController.viewContext.save()
                    }
                }
            }
        }
        else {
            cell.imageView.image = UIImage(named: "VirtualTourist_76")
        }
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if photosURL != nil {
            return photosURL.count
        }
        else if savedPhotos != nil {
            return savedPhotos.count
        }
        else {
            return 0
        }
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let space:CGFloat = 1.0
        let dimension = (view.frame.size.width - (space)) / 3

        return CGSize(width: dimension, height: dimension)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if photosURL != nil {
            let photo = fetchPhoto(url: photosURL[indexPath.row])!
            photosURL.remove(at: indexPath.row)
            dataController.viewContext.delete(photo)
        }
        else {
            let photo = savedPhotos[indexPath.row]
            savedPhotos.remove(at: indexPath.row)
            dataController.viewContext.delete(photo)
        }
        try! dataController.viewContext.save()
        collectionView.reloadData()
    }
}
