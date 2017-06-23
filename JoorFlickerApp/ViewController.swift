//
//  ViewController.swift
//  JoorFlickerApp
//
//  Created by Colin on 6/19/17.
//  Copyright © 2017 Colin Taylor. All rights reserved.
//

import UIKit

let flickrAPIKey = "221e4e1571ddb398f48c14f6f7c9822f"

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, URLSessionDelegate {

    let pageSize:Int = 25
    
    var data:[FlickrImage] = [FlickrImage]()
    var firstPage:Int = 0
    var lastPage:Int = 0
    var totalImages:Int = 0
    var totalPages:Int = 0
    var isLoading:Bool = false
    var loadingPageNum:Int = -1
    var loadingImages = [FlickrImage]()
    var searchString:String = ""
    var isConnected:Bool = true
    
    @IBOutlet weak var imageTable: UITableView!
    @IBOutlet weak var flickerSearchBar: UISearchBar!
    @IBOutlet weak var AlertButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        flickerSearchBar.showsBookmarkButton = false
        flickerSearchBar.text = searchString
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func saveResultsURL()->URL {
        let fileManager = FileManager.default
        let dirs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last
        var filename = dirs
        
        filename?.appendPathComponent("lastFlickrSearchResult")
        return filename!
    }
    
    func saveResultsToFile() {
        //create the dictionary of important information.
        //data array, firstPage, LastPage, TotalPages, totalImages, searchBar.text
        var saveDict:[String:Any] = [String:Any]()
        saveDict["title"] = self.flickerSearchBar.text
        saveDict["firstPage"] = self.firstPage
        saveDict["lastPage"] = self.lastPage
        saveDict["totalPages"] = self.totalPages
        saveDict["totalImages"] = self.totalImages
        saveDict["imageData"] = self.data
        
        //save file path
        let filename = self.saveResultsURL()
        let filePath:String = filename.path
        
        //save the contents of the dictionary
        let success = NSKeyedArchiver.archiveRootObject(saveDict, toFile: filePath)
        if !success {
            print("failed to save the class to file.")
        } else {
            print("saved to file")
        }

    }
    
    func restoreResultsFromFile() {
        let fileManager = FileManager.default
        let fileURL = self.saveResultsURL()
        if fileManager.fileExists(atPath: fileURL.path) {
            let storedResultsDict:[String:Any] = NSKeyedUnarchiver.unarchiveObject(withFile: self.saveResultsURL().path) as! [String : Any]
            if storedResultsDict.count == 0 {
                fatalError("failed to unarchive the file into a valid dictionary")
            } else {
                //self.flickerSearchBar.text
                self.searchString = storedResultsDict["title"] as! String
                self.firstPage = storedResultsDict["firstPage"] as! Int
                self.lastPage = storedResultsDict["lastPage"] as! Int
                self.totalPages = storedResultsDict["totalPages"] as! Int
                self.totalImages = storedResultsDict["totalImages"] as! Int
                self.data = storedResultsDict["imageData"] as! [FlickrImage]
                
            }
            
        }
    }
    
    func deleteLocalResultsStorage() {
        let fileManager = FileManager.default
        let fileURL = self.saveResultsURL()
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                print("failed to remove the saveResults file")
            }

        }
    }
    
    @IBAction override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "FullScreenImageSegue" {
            let navControl = segue.destination as? UINavigationController
            guard let fullImageController = navControl?.topViewController as? FullImageController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            fullImageController.flickrImage = data[self.offsetArrayIndex(passedIndex: (imageTable.indexPathForSelectedRow?.row)!)]
        }
    }
    @IBAction func unwindFromPhoto(segue: UIStoryboardSegue) {
        //don't actually need to do anything.
    }
    
    // MARK: - Search bar Delegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        flickerSearchBar.text = ""
        data = [FlickrImage]()
        firstPage = 0
        lastPage = 0
        totalImages = 0
        totalPages = 0
        loadingPageNum = -1
        isLoading = false
        
        self.deleteLocalResultsStorage()
        
        imageTable.reloadData()
    }
    /*
    "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(flickrAPIKey)&tags=\(flickerSearchBar.text)&per_page=25&format=json&nojsoncallback=1"
     */
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !isLoading {
            data = [FlickrImage]()
            isLoading = true
            firstPage = 0
            lastPage = 0
            totalImages = 0
            totalPages = 0
            loadingPageNum = -1
            
            self.loadNextPage()
            
            imageTable.reloadData()
        }
    }
    
    @IBAction func noInternetConnection(_ sender: Any) {
        let alert = UIAlertController(title: "No Internet Connection", message: "We are unable to connect to the internet currently. You may continue to browse any previously loaded content.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil ))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func offsetArrayIndex(passedIndex:Int) -> Int {
        return passedIndex - pageSize*firstPage
    }
    
    func loadNextPage() {
        self.loadPage(pageNumber: lastPage+1)
    }
    func loadPrevPage() {
        self.loadPage(pageNumber: firstPage-1)
    }
    func loadPage(pageNumber:Int) {
        //to protect against using pictures with a license you can add &license=7
        let searchURL:URL = URL.init(string: "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(flickrAPIKey)&tags=\(flickerSearchBar.text ?? "kittens")&page=\(pageNumber)&per_page=\(pageSize)&sort=date-posted-desc&format=json&nojsoncallback=1&media=photos")!
        let session = URLSession.init(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        let sessionTask:URLSessionDownloadTask = session.downloadTask(with: searchURL, completionHandler: {(url:URL?,response:URLResponse?,error:Error?) in
            if error == nil{
                if !self.isConnected {
                    self.isConnected = true
                }
                do {
                    let data:Data = try Data.init(contentsOf: url!)
                    let responseDictionary:Dictionary? = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]
                    let photosDict = responseDictionary?["photos"] as? [String: Any]
                    self.totalImages = Int(photosDict?["total"] as! String)!
                    self.totalPages = photosDict?["pages"] as! Int
                    self.loadingPageNum = photosDict?["page"] as! Int
                    let photosArray = photosDict?["photo"] as? [Any]
                    for photo in photosArray!{
                        let photoInfoDict = photo as! NSDictionary
                        let flickrImage:FlickrImage = FlickrImage.init(contents: photoInfoDict as! [String:Any])
                        
                        self.downloadPreviewImage(session: session, flickrImage:flickrImage)
                        self.downloadFullImage(session: session, flickrImage:flickrImage)
                        
                        self.loadingImages.append(flickrImage)
                        
                    }
                } catch {
                    print("Error was nil but something failed in deserializing the data")
                }
            } else if (error as! URLError).code == URLError.notConnectedToInternet {
                if self.isConnected {
                    self.isConnected = false
                    self.noInternetConnection(self)
                }
            }else {
                print("error response when connecting to flicker: \(String(describing: error))" )
            }
        } )
        sessionTask.resume()
        session.finishTasksAndInvalidate()
    }
    
    //download the image at the url
    func downloadPreviewImage(session:URLSession, flickrImage:FlickrImage) {
        let imageURL:URL = URL.init(string: flickrImage.previewImagePath)!
        let sessionTask:URLSessionDownloadTask = session.downloadTask(with: imageURL, completionHandler: {(url:URL?,response:URLResponse?,error:Error?) in
            
            do {
                if (error == nil){
                    let data:Data = try Data.init(contentsOf: url!)
                    let downloadedImage:UIImage = UIImage(data: data)!
                    flickrImage.previewImage = downloadedImage
                } else {
                    print("error response when downloading file at URL: \(imageURL)")
                }
            } catch {
                print("Error converting downloaded data into a UIImage or adding it to the contentImages array")
            }
        } )
        sessionTask.resume()
        
    }
    
    func downloadFullImage(session:URLSession, flickrImage:FlickrImage) {
        let imageURL:URL = URL.init(string: flickrImage.fullImagePath)!
        let sessionTask:URLSessionDownloadTask = session.downloadTask(with: imageURL, completionHandler: {(url:URL?,response:URLResponse?,error:Error?) in
            
            do {
                if (error == nil){
                    let data:Data = try Data.init(contentsOf: url!)
                    let downloadedImage:UIImage = UIImage(data: data)!
                    flickrImage.fullImage = downloadedImage
                } else {
                    print("error response when downloading file at URL: \(imageURL)")
                }
            } catch {
                print("Error converting downloaded data into a UIImage or adding it to the contentImages array")
            }
        } )
        sessionTask.resume()
        
    }
    
    
    // MARK: - Table View Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if data.count == 0 && !isLoading {
            return 0
        } else if data.count == 0 && isLoading {
            return 1
        }else if !isConnected {
            return data.count
        } else {
            return totalImages
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // if we hit an end of the data and we need to load more trigger that. (should already have been triggered but I have seen instances where it didn't)
        let index = self.offsetArrayIndex(passedIndex: indexPath.row)
        if index >= data.count && lastPage != totalPages {
            if !isLoading {
                isLoading = true
                self.loadNextPage()
            }
        }else if firstPage > 0 && indexPath.row <= pageSize*firstPage {
            if !isLoading {
                isLoading = true
                //load more into data here
                self.loadPrevPage()
            }
        }
        
        if index == 0 && data.count == 0 && isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
            return cell
        } else if index >= data.count && isLoading {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
                return cell
        } else if firstPage != 0 && indexPath.row <= pageSize*firstPage && isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageInfoCell", for: indexPath) as! ImageInfoCell
            cell.ImageNameLabel.text = data[index].titleString
            cell.ImagePreview.image = data[index].previewImage
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let index = self.offsetArrayIndex(passedIndex: indexPath.row)
        if index == data.count-pageSize && totalPages != lastPage {
            //load more into data here
            if !isLoading {
                isLoading = true
                self.loadNextPage()
            }
        } else if firstPage != 0 && index == pageSize {
            if !isLoading {
                isLoading = true
                //load more into data here
                self.loadPrevPage()
            }
        }
    }
    
    //MARK: URLSessionDelegate
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if isLoading {
            performSelector(onMainThread: #selector(toggleAlertButton), with: nil, waitUntilDone: false)
            if (error == nil) {
                if loadingPageNum >= lastPage { //loading the next page
                    performSelector(onMainThread: #selector(updateForNextPage), with: nil, waitUntilDone: false)
                    
                } else if 0 <= loadingPageNum && loadingPageNum <= firstPage { //loading a page that we have already seen.
                    performSelector(onMainThread: #selector(updateForPrevPage), with: nil, waitUntilDone: false)
                    
                } else {
                    performSelector(onMainThread: #selector(reloadData), with: nil, waitUntilDone: false)
                    isLoading = false
                }
                
            } else {
                print("URLSession had an error: \(String(describing: error))")
                self.isLoading = false
                
            }
        }
    }
    func reloadData() {
        imageTable.reloadData()
    }
    func toggleAlertButton() {
        AlertButton.isHidden = isConnected
    }
    
    func updateForNextPage() {
        
        data.append(contentsOf: loadingImages)
        
        if data.count > 200 {
            data = Array(data.dropFirst(pageSize))
            firstPage += 1
        }
        imageTable.reloadData()
        
        lastPage += 1
        isLoading = false
        loadingImages = [FlickrImage]()

    }
    
    func updateForPrevPage() {
        loadingImages.append(contentsOf: data)
        data = loadingImages
    
        if data.count > 200 {
            var i = data.count - pageSize
            var deletionIndices:[IndexPath] = [IndexPath]()
            while i != data.count {
                deletionIndices.append(IndexPath.init(row: i, section: 0))
                i += 1
            }
            data = Array(data.dropLast(pageSize))
            lastPage -= 1
        }
        imageTable.reloadData()
        
        firstPage -= 1
        isLoading = false
        loadingImages = [FlickrImage]()

    }
}

