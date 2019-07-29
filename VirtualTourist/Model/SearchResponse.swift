//
//  SearchResponse.swift
//  VirtualTourist
//
//  Created by Mohamed Metwaly on 2019-05-29.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation

struct SearchResponse:Codable {
    
    let photos:PhotosResponse
    let stat: String
    
}
