//
//  flickrImage.swift
//  JoorFlickerApp
//
//  Created by Colin on 6/20/17.
//  Copyright © 2017 Colin Taylor. All rights reserved.
//

import Foundation
import UIKit

class FlickrImage: NSObject, NSCoding {
    
    let imageID:String
    let titleString:String
    let previewImagePath:String
    var previewImage:UIImage?
    let fullImagePath:String
    var fullImage:UIImage?

    //MARK: types
    struct PropertyKey {
        static let imageID = "imageID"
        static let title = "titleString"
        static let previewImagePath = "previewImagePath"
        static let previewImage = "previewImage"
        static let fullImagePath = "fullImagePath"
        static let fullImage = "fullImage"
    }
    
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
    init(id:String, title:String, previewPath:String, fullPath:String) {
        imageID = id
        titleString = title
        previewImagePath = previewPath
        fullImagePath = fullPath
        
        super.init()

    }
    
    //MARK: Coding functions
    func encode(with aCoder: NSCoder) {
        aCoder.encode(imageID, forKey: PropertyKey.imageID)
        aCoder.encode(titleString, forKey: PropertyKey.title)
        aCoder.encode(previewImagePath, forKey: PropertyKey.previewImagePath)
        aCoder.encode(previewImage, forKey: PropertyKey.previewImage)
        aCoder.encode(fullImagePath, forKey: PropertyKey.fullImagePath)
        aCoder.encode(fullImage, forKey: PropertyKey.fullImage)
    }
    
    required convenience init?(coder aDecoder:NSCoder) {
        self.init(id:aDecoder.decodeObject(forKey: PropertyKey.imageID) as! String , title: aDecoder.decodeObject(forKey: PropertyKey.title) as! String, previewPath: aDecoder.decodeObject(forKey: PropertyKey.previewImagePath) as! String, fullPath: aDecoder.decodeObject(forKey: PropertyKey.fullImagePath) as! String)
        
        self.previewImage = (aDecoder.decodeObject(forKey: PropertyKey.previewImage) as! UIImage)
        self.fullImage = (aDecoder.decodeObject(forKey: PropertyKey.fullImage) as! UIImage)
        
    }

}
