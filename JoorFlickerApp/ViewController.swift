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
    var totalPages:Int = 300//temp value for initial pagination testing
    var isLoading:Bool = false
    var loadingPageNum:Int = 0
    var loadingImages = [FlickrImage]()
    
    
    @IBOutlet weak var imageTable: UITableView!
    @IBOutlet weak var flickerSearchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        flickerSearchBar.showsBookmarkButton = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "FullScreenImageSegue" {
            let navControl = segue.destination as? UINavigationController
            guard let fullImageController = navControl?.topViewController as? FullImageController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            fullImageController.flickrImage = data[(imageTable.indexPathForSelectedRow?.row)!]
        }
    }
    @IBAction func unwindFromPhoto(segue: UIStoryboardSegue) {
        //don't actually need to do anything.
    }
    
    // MARK: - Search bar Delegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        flickerSearchBar.text = ""
        data = [FlickrImage]()
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
            totalPages = 0
            loadingPageNum = 0
            
            self.loadNextPage()
            
            imageTable.reloadData()
        }
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
            if(error == nil){
                do {
                    let data:Data = try Data.init(contentsOf: url!)
                    let responseDictionary:Dictionary? = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any]
                    let photosDict = responseDictionary?["photos"] as? [String: Any]
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
            } else {
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
        if isLoading {
            return data.count+1
        } else {
            return data.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // if we hit an end of the data and we need to load more trigger that. (should already have been triggered but I have seen instances where it didn't)
        if indexPath.row == data.count && lastPage != totalPages {
            if !isLoading {
                isLoading = true
                self.loadNextPage()
            }
        }else if firstPage > 1 && indexPath.row == 0 {
            if !isLoading {
                isLoading = true
                //load more into data here
                self.loadPrevPage()
            }
        }
        
        if indexPath.row == 0 && data.count == 0 && isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
            return cell
        } else if indexPath.row == data.count && isLoading {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
                return cell
        } else if firstPage != 1 && indexPath.row == 0 && isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageInfoCell", for: indexPath) as! ImageInfoCell
            cell.ImageNameLabel.text = data[indexPath.row].titleString
            cell.ImagePreview.image = data[indexPath.row].previewImage
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == data.count-pageSize && totalPages != lastPage {
            //load more into data here
            if !isLoading {
                isLoading = true
                self.loadNextPage()
            }
        } else if firstPage != 1 && indexPath.row == pageSize {
            if !isLoading {
                isLoading = true
                //load more into data here
                self.loadPrevPage()
            }
        }
    }
    
    //MARK: URLSessionDelegate
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if (error == nil) {
            if loadingPageNum > lastPage { //loading the next page
                var nextIndex:Int = data.count
                let newLength:Int = data.count+loadingImages.count
                var newIndices:[IndexPath] = [IndexPath]()
                while nextIndex != newLength {
                    newIndices.append(IndexPath.init(row: nextIndex, section: 0))
                    nextIndex += 1
                    
                }
                performSelector(onMainThread: #selector(updateForNextPage(indices:)), with: newIndices, waitUntilDone: false)

            } else if loadingPageNum < firstPage { //loading a page that we have already seen.
                if firstPage == 1 {
                    
                }
                var nextIndex:Int = 0
                var newIndices:[IndexPath] = [IndexPath]()
                while nextIndex != pageSize {
                    newIndices.append(IndexPath.init(row: nextIndex, section: 0))
                    nextIndex += 1
                }
                performSelector(onMainThread: #selector(updateForPrevPage(indices:)), with: newIndices, waitUntilDone: false)

            } else {
                //this would be bad we should only be loading pages that are outside our existing range.
                print("loading page: (\(loadingPageNum)) is between FirstPage: \(firstPage) and lastPage: \(lastPage)")
                isLoading = false
            }
            
        } else {
            print("URLSession had an error: \(error)")
        }
        
    }

    func updateForNextPage(indices:[IndexPath]) {
        let visibleIndices = imageTable.indexPathsForVisibleRows
        
        data.append(contentsOf: loadingImages)
        imageTable.beginUpdates()
        imageTable.insertRows(at: indices, with: UITableViewRowAnimation.bottom)
        imageTable.endUpdates()
        
        if data.count > 200 {
            data = Array(data.dropFirst(pageSize))
            var deletionIndices:[IndexPath] = [IndexPath]()
            var i = 0
            while i != pageSize {
                deletionIndices.append(IndexPath.init(row: i, section: 0))
                i += 1
            }
            imageTable.beginUpdates()
            imageTable.deleteRows(at: deletionIndices, with: UITableViewRowAnimation.automatic)
            imageTable.scrollToRow(at: IndexPath.init(row: (visibleIndices?.last?.row)!-pageSize, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
            imageTable.reloadData()
            imageTable.endUpdates()
            firstPage += 1
        } else {
            imageTable.reloadData()
        }
        
        lastPage += 1
        isLoading = false
        loadingImages = [FlickrImage]()

    }
    
    func updateForPrevPage(indices:[IndexPath]) {
        let visibleIndices = imageTable.indexPathsForVisibleRows
        loadingImages.append(contentsOf: data)
        data = loadingImages
        imageTable.beginUpdates()
        imageTable.insertRows(at: indices, with: UITableViewRowAnimation.top)
        imageTable.endUpdates()
        
        if data.count > 200 {
            var i = data.count - pageSize
            var deletionIndices:[IndexPath] = [IndexPath]()
            while i != data.count {
                deletionIndices.append(IndexPath.init(row: i, section: 0))
                i += 1
            }
            data = Array(data.dropLast(pageSize))
            imageTable.beginUpdates()
            imageTable.deleteRows(at: deletionIndices, with: UITableViewRowAnimation.bottom)
            imageTable.scrollToRow(at: IndexPath.init(row: (visibleIndices?.last?.row)! + pageSize, section: 0), at: UITableViewScrollPosition.top, animated: false)
            imageTable.reloadData()
            imageTable.endUpdates()
            
            lastPage -= 1
        } else {
            imageTable.reloadData()
        }
        firstPage -= 1
        isLoading = false
        loadingImages = [FlickrImage]()

    }
}

