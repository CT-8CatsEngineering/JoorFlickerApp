//
//  ViewController.swift
//  JoorFlickerApp
//
//  Created by Colin on 6/19/17.
//  Copyright © 2017 Colin Taylor. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let pageSize:Int = 25
    
    var data:[Int] = [Int]()
    var initialIndex:Int = 0
    var lastIndex:Int = 0
    var totalImages:Int = 300//temp value for initial pagination testing
    var isLoading:Bool = false
    
    
    @IBOutlet weak var imageTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        data = [Int](arrayLiteral: 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25)
        lastIndex = data.index(of: data.last!)!
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if lastIndex == totalImages {
            return data.count
        } else {
            return data.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("indexPath: \(indexPath), dataCount: \(data.count), lastData object:\(data.last!)")
        if indexPath.row == data.count {
            if lastIndex != totalImages {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
                return cell
            }
        }
        if initialIndex != 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageInfoCell", for: indexPath) as! ImageInfoCell
            cell.ImageNameLabel.text = "Index: \(data[indexPath.row])"
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == data.count-pageSize && totalImages != lastIndex { //you might decide to load sooner than -1 I guess...
            //load more into data here
            if !isLoading {
                isLoading = true
                var nextIndex:Int = data.count
                let newLength:Int = data.count+pageSize
                var newIndices:[IndexPath] = [IndexPath]()
                var nextValue:Int = data.last!+1//will not be necessary in final app just for initial testing
                while nextIndex != newLength {
                    data.append(nextValue)
                    newIndices.append(IndexPath.init(row: nextIndex, section: 0))
                    nextIndex += 1
                    nextValue += 1
                }
                imageTable.beginUpdates()
                imageTable.insertRows(at: newIndices, with: UITableViewRowAnimation.automatic)
                imageTable.endUpdates()
                
                if data.count > 200 {
                    data = Array(data.dropFirst(pageSize))
                    var deletionIndices:[IndexPath] = [IndexPath]()
                    var i = 0
                    while i != pageSize {
                        deletionIndices.append(IndexPath.init(row: i, section: 0))
                        i += 1
                    }
                    print("deletionIndices: \(deletionIndices)")
                    imageTable.beginUpdates()
                    imageTable.deleteRows(at: deletionIndices, with: UITableViewRowAnimation.automatic)
                    imageTable.endUpdates()
                    imageTable.scrollToRow(at: IndexPath.init(row: indexPath.row-pageSize, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
                    initialIndex += pageSize
                }
                
                lastIndex = data.count + initialIndex
                imageTable.reloadData()
                isLoading = false
            }
        } else if initialIndex != 0 && indexPath.row == pageSize {
            if !isLoading {
                isLoading = true
                //load more into data here
                var nextIndex:Int = initialIndex-pageSize
                print("initialIndex: \(initialIndex), nextIndex: \(nextIndex), IndexPath: \(indexPath)")
                var tmpData:[Int] = [Int]()
                var newIndices:[IndexPath] = [IndexPath]()
                while nextIndex != initialIndex {
                    tmpData.append(nextIndex)
                    newIndices.append(IndexPath.init(row: nextIndex, section: 0))
                    nextIndex += 1
                }
                tmpData.append(contentsOf: data)
                data = tmpData
                imageTable.beginUpdates()
                imageTable.insertRows(at: newIndices, with: UITableViewRowAnimation.top)
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
                    imageTable.endUpdates()
                    
                    imageTable.scrollToRow(at: IndexPath.init(row: indexPath.row + pageSize, section: 0), at: UITableViewScrollPosition.top, animated: false)

                    
                }
                initialIndex -= pageSize
                lastIndex = data.count + initialIndex
                imageTable.reloadData()
                isLoading = false
            }
        }
    }
}

