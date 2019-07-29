//
//  PhotosResponse.swift
//  VirtualTourist
//
//  Created by Mohamed Metwaly on 2019-05-29.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation

struct PhotosResponse: Codable {
    
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [PhotoResponse]
    
}
