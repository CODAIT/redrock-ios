//
//  RIghtViewController.swift
//  Spark Insights
//
//  Created by Jonathan Alter on 5/28/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit

class RightViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var textField: UITextField!

    @IBOutlet weak var tableA: UITableView!
    @IBOutlet weak var tableB: UITableView!
    @IBOutlet weak var doneButton: UIButton!
    
    private var listA: RefArray?
    private var listB: RefArray?
    
    private var tempView: UIView?
    
    private var dragging = false
    private var panning = false
    private var draggedIndex = -1
    
    private var fromTable: UITableView!
    private var toTable: UITableView!
    
    private var fromList: RefArray?
    private var toList: RefArray?
    
    private var beginDraggingRect: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listA = RefArray(arr:["one", "two", "three"])
        listB = RefArray(arr: ["#1", "#2", "#3"])
        
        // UI Tweaks
        var spacerView = UIView(frame: CGRectMake(0, 0, 10, textField.frame.size.height)) // Setting text inset
        textField.leftViewMode = .Always
        textField.leftView = spacerView
        textField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSForegroundColorAttributeName: Config.sideSearchTextFieldPlaceholderColor])
        
        // Add Gesture Recognizers
        var gr1a = UISwipeGestureRecognizer(target: self, action: "handleSwipeA:")
        gr1a.direction = .Right
        gr1a.numberOfTouchesRequired = 1
        tableA.addGestureRecognizer(gr1a)
        
        var gr1aa = UISwipeGestureRecognizer(target: self, action: "handleSwipeA:")
        gr1aa.direction = .Left
        gr1aa.numberOfTouchesRequired = 1
        tableA.addGestureRecognizer(gr1aa)
        
        var gr2a = UILongPressGestureRecognizer(target: self, action: "handleLPA:")
        tableA.addGestureRecognizer(gr2a)
        
        var gr3a = UIPanGestureRecognizer(target: self, action: "handlePanA:")
        gr3a.delegate = self
        tableA.addGestureRecognizer(gr3a)
        
        
        var gr1b = UISwipeGestureRecognizer(target: self, action: "handleSwipeB:")
        gr1b.direction = .Right
        gr1b.numberOfTouchesRequired = 1
        tableB.addGestureRecognizer(gr1b)
        
        var gr1bb = UISwipeGestureRecognizer(target: self, action: "handleSwipeB:")
        gr1bb.direction = .Left
        gr1bb.numberOfTouchesRequired = 1
        tableB.addGestureRecognizer(gr1bb)
        
        var gr2b = UILongPressGestureRecognizer(target: self, action: "handleLPB:")
        tableB.addGestureRecognizer(gr2b)
        
        var gr3b = UIPanGestureRecognizer(target: self, action: "handlePanB:")
        gr3b.delegate = self
        tableB.addGestureRecognizer(gr3b)
        
        // Set TextFieldDelegate
        self.textField.delegate = self
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var list = (tableView === tableA) ? listA?.array : listB?.array
        return list!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var list = (tableView === tableA) ? listA?.array : listB?.array
        var identifier = (tableView === tableA) ? "IncludeCell" : "ExcludeCell"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(identifier) as! UITableViewCell
        
        var label = cell.viewWithTag(100) as! UILabel
        var cellText = list?[indexPath.row] as! String
        label.text = cellText

        return cell
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (!textField.text.isEmpty) {
            listA?.array?.append(textField.text)
            tableA.reloadData()
            textField.text = ""
        }
        return false
    }
    
    // MARK: - Drag and Drop
    
    func cancelDragging() {
        println(__FUNCTION__)
        if (!dragging) {
            return
        }
        
        tempView?.removeFromSuperview()
        tempView = nil
        
        dragging = false
        panning = false
        draggedIndex = -1
        fromTable = nil
        toTable = nil
        fromList = nil
        toList = nil
    }
    
    func startDragging(draggingIndex: Int, draggedName: String, draggedColor: UIColor, location: CGPoint) {
        println(__FUNCTION__)
        dragging = true
        draggedIndex = draggingIndex
        tempView = UIView(frame: CGRectMake(0, 0, 100, 34))
        tempView?.backgroundColor = Config.sideSearchTextFieldColor
        var label = UILabel(frame: tempView!.bounds)
        label.text = draggedName
        label.backgroundColor = UIColor.blackColor()
        label.textColor = draggedColor
        tempView?.addSubview(label)
        self.view.addSubview(tempView!)
        tempView?.center = location
        beginDraggingRect = tempView?.frame
    }
    
    func handleSwipe(gestureRecongnizer: UIGestureRecognizer, table: UITableView, list: RefArray) {
        var state = gestureRecongnizer.state
        
        var loc = gestureRecongnizer.locationInView(table)
        println("SWIPE (\(stateToString(state))) (\(loc.x),\(loc.y))")
        
        var indexPath = table.indexPathForRowAtPoint(loc)
        
        if (indexPath == nil) {
            return
        }
        
        var cell = table.cellForRowAtIndexPath(indexPath!)
        
        if (cell == nil) {
            return
        }
        
        var label = cell?.viewWithTag(100) as! UILabel
        var title = label.text
        var color = label.textColor
        
        if (indexPath!.row >= list.array!.count) {
            return
        }
        
        if (state != UIGestureRecognizerState.Ended) {
            return
        }
        
        if (dragging) {
            self.cancelDragging()
        }
        
        startDragging(indexPath!.row, draggedName: title!, draggedColor: color, location: gestureRecongnizer.locationInView(self.view))
    }
    
    func handleSwipeA(gestureRecognizer: UIGestureRecognizer) {
        println(__FUNCTION__)
        fromTable = tableA
        toTable = tableB
        fromList = listA
        toList = listB
        self.handleSwipe(gestureRecognizer, table: fromTable, list: fromList!)
    }
    
    func handleSwipeB(gestureRecognizer: UIGestureRecognizer) {
        println(__FUNCTION__)
        fromTable = tableB
        toTable = tableA
        fromList = listB
        toList = listA
        self.handleSwipe(gestureRecognizer, table: fromTable, list: fromList!)
    }
    
    func handleLP(gestureRecognizer: UIGestureRecognizer, table: UITableView, list: RefArray) {
        println(__FUNCTION__)
        var state = gestureRecognizer.state
        var loc = gestureRecognizer.locationInView(table)
        println("LP (\(stateToString(state))) (\(loc.x),\(loc.y))")
        
        var indexPath = table.indexPathForRowAtPoint(loc)
        
        if (indexPath == nil) {
            return
        }
        
        var cell = table.cellForRowAtIndexPath(indexPath!)
        
        if (cell == nil) {
            return
        }
        
        var label = cell?.viewWithTag(100) as! UILabel
        var title = label.text
        var color = label.textColor
        
        if (indexPath!.row >= list.array!.count) {
            println("Non in any row")
            return
        }
        
        if (state == UIGestureRecognizerState.Began) {
            if (dragging) {
                self.cancelDragging()
            }
            
            self.startDragging(indexPath!.row, draggedName: title!, draggedColor: color, location: gestureRecognizer.locationInView(self.view))
        } else if (state == UIGestureRecognizerState.Ended) {
            if (dragging && !panning) {
                self.cancelDragging()
            }
        }
    }
    
    func handleLPA(gestureRecognizer: UIGestureRecognizer) {
        println(__FUNCTION__)
        fromTable = tableA
        toTable = tableB
        fromList = listA
        toList = listB
        self.handleLP(gestureRecognizer, table: fromTable, list: fromList!)
    }
    
    func handleLPB(gestureRecognizer: UIGestureRecognizer) {
        println(__FUNCTION__)
        fromTable = tableB
        toTable = tableA
        fromList = listB
        toList = listA
        self.handleLP(gestureRecognizer, table: fromTable, list: fromList!)
    }
    
    func handlePan(gestureRecognizer: UIGestureRecognizer) {
        println(__FUNCTION__)
        
        var state = gestureRecognizer.state
        var loc = gestureRecognizer.locationInView(self.view)
        
        if (state == UIGestureRecognizerState.Began) {
            panning = true
        }
        
        if (state == UIGestureRecognizerState.Ended) {
            if (dragging) {
                var locInView = gestureRecognizer.locationInView(fromTable)
                if (CGRectContainsPoint(fromTable.bounds, locInView)) {
                    println("Dropped in FROM table")
                    return cancel()
                }
                
                locInView = gestureRecognizer.locationInView(toTable)
                if (CGRectContainsPoint(fromTable.bounds, locInView)) {
                    println("Dropped in TO table")
                    var rowData: AnyObject = fromList!.array!.removeAtIndex(draggedIndex)
                    toList!.array!.append(rowData)
                    
                    var arr = [NSIndexPath(forRow: draggedIndex, inSection: 0)]
                    fromTable.deleteRowsAtIndexPaths(arr, withRowAnimation: UITableViewRowAnimation.Automatic)
                    
                    var row = toList!.array!.count-1
                    arr = [NSIndexPath(forRow: row, inSection: 0)]
                    toTable.insertRowsAtIndexPaths(arr, withRowAnimation: UITableViewRowAnimation.Automatic)
                    
                    self.cancelDragging()
                    return
                }
                
                 cancel()
            }
        }
        
        if (dragging) {
            tempView?.center = loc
        }
        
    }
    
    func cancel() {
        // TODO:Fix animation to return to table if dropped outside a TableView
//        println(__FUNCTION__)
//        println("frame: \(self.tempView!.frame)")
//        println("bgrect: \(beginDraggingRect)")
//        UIView.animateWithDuration(0.5, animations: {
//            self.tempView?.frame = beginDraggingRect!
//            }, completion: {(finished: Bool) in
//            self.cancelDragging()
//        })
        
        self.cancelDragging()
    }
    
    func handlePanA(gestureRecognizer: UIGestureRecognizer) {
        println("PAN:" + __FUNCTION__)
        handlePan(gestureRecognizer)
    }
    
    func handlePanB(gestureRecognizer: UIGestureRecognizer) {
        println(__FUNCTION__)
        handlePan(gestureRecognizer)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - Actions
    
    @IBAction func doneClicked(sender: AnyObject) {
        
    }
    
    
    // MARK: - Utilities
    
    func stateToString(state: UIGestureRecognizerState) -> (String) {
        switch state {
        case .Possible:
            return "Possible"
        case .Began:
            return "Began"
        case .Changed:
            return "Changed"
        case .Ended:
            return "Ended"
        case .Cancelled:
            return "Cancelled"
        case .Failed:
            return "Failed"
        default:
            return "UNKNOWN"
        }
    }
    
    // MARK: Utility Classes
    
    // Pass an Array by reference
    class RefArray {
        var array: Array<AnyObject>?
        
        init(arr: Array<AnyObject>) {
            array = arr
        }
    }
}
