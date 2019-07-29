//
//  PhotoResponse.swift
//  VirtualTourist
//
//  Created by Mohamed Metwaly on 2019-05-29.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation

struct PhotoResponse: Codable {
    
    let id:String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let isPublic: Int
    let isFriend: Int
    let isFamily: Int
    let url: String
    
    enum CodingKeys: String , CodingKey {
        case id
        case owner
        case secret
        case server
        case farm
        case title
        case isPublic = "ispublic"
        case isFriend = "isfriend"
        case isFamily = "isfamily"
        case url = "url_n"
    }
}
