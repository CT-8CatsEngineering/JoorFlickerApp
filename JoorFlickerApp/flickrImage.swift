//
//  flickrImage.swift
//  JoorFlickerApp
//
//  Created by Colin on 6/20/17.
//  Copyright © 2017 Colin Taylor. All rights reserved.
//

import Foundation
import UIKit

class FlickrImage: NSObject {
    
    let imageID:String
    let titleString:String
    let previewImagePath:String
    var previewImage:UIImage?
    let fullImagePath:String
    var fullImage:UIImage?
    
    init(contents:[String:Any]) {
        
        imageID = contents["id"] as! String
        titleString = contents["title"] as! String
        
        let farmID:Int64 = contents["farm"] as! Int64
        let serverID:String = contents["server"] as! String
        let photoSecret:String = contents["secret"] as! String

        previewImagePath = "https://farm\(farmID).staticflickr.com/\(serverID)/\(imageID)_\(photoSecret)_s.jpg"
        fullImagePath = "https://farm\(farmID).staticflickr.com/\(serverID)/\(imageID)_\(photoSecret)_h.jpg"
        
        super.init()
    }
    
}
