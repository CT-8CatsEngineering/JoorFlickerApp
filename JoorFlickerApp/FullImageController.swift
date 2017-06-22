//
//  FullImageController.swift
//  JoorFlickerApp
//
//  Created by Colin on 6/21/17.
//  Copyright © 2017 Colin Taylor. All rights reserved.
//

import Foundation
import UIKit

class FullImageController: UIViewController {

    @IBOutlet weak var FullScreenImageView: UIImageView!
    @IBOutlet weak var NavigationItem: UINavigationItem!
    var flickrImage:FlickrImage?
    
    override func viewDidLoad() {
        NavigationItem.title = flickrImage?.titleString
        FullScreenImageView.image = flickrImage?.fullImage
    }
    @IBAction func performUnwindSegue(_ sender: Any) {
        performSegue(withIdentifier: "unwindfromPhotoSegue", sender: self)
    }

}
