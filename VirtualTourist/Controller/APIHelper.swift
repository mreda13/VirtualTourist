//
//  APIHelper.swift
//  VirtualTourist
//
//  Created by Mohamed Metwaly on 2019-05-27.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation


class APIHelper {
    
    static var nonce:Int = 1
    static var baseURL = "https://www.flickr.com/services/rest/?"
    
    struct Auth {
        static var key = "0e578d32f0eaae39c61902b6bdc84b52"
    }
    
    enum Endpoints {
        
        case getPhotos(lat:Double,lon:Double,page:Int?)
        
        var stringValue:String {
            switch self {
            case .getPhotos(let lat, let lon, let page):
                var URL = APIHelper.baseURL + "method=flickr.photos.search"
                URL = URL + "&api_key=\(Auth.key)"
                URL = URL + "&lat=\(lat)&lon=\(lon)"
                URL = URL + "&extras=url_n&per_page=30"
                if let page = page {
                    URL = URL + "&page=\(page)"
                }
                URL = URL + "&format=json&nojsoncallback=1"
                return URL
            }
        }
        
        var url: URL {
            return URL(string:stringValue)!
        }
    }
    
    class func taskForGetRequest(request: URLRequest, completion: @escaping (Data?,URLResponse?,Error?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(nil,response,error)
                return
            }
            completion(data,response,nil)
        }
        task.resume()
    }
    
    class func getPhotos(lat: Double, lon: Double,page: Int?, completion: @escaping ([String]?,URLResponse?,Int,Error?)->Void) {
        
        let request = URLRequest(url: Endpoints.getPhotos(lat: lat, lon: lon, page: page).url)
        
        taskForGetRequest(request: request) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil,response,0,error)
                    return
                }
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil,response,0,error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            
            do {
                let jsonRes = try decoder.decode(SearchResponse.self, from: data)
                let pages = jsonRes.photos.pages
                let photos = jsonRes.photos.photo
                var photoIDs = [String]()
                
                for photo in photos {
                    photoIDs.append(photo.url)
                }
                
                DispatchQueue.main.async {
                    if pages > 1 {
                        completion(photoIDs,response,pages,nil)
                    }
                    else {
                        completion(photoIDs,response,pages,nil)
                    }
                }
            }
            catch {
                DispatchQueue.main.async {
                    completion(nil,response,0,error)
                }
            }
        }
    }
}
