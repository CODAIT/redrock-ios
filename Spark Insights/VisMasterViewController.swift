//
//  VisMasterViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/12/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit

enum VisTypes {
    case TreeMap
    case CirclePacking
    case ForceGraph
    case StackedBar
    case TimeMap
}

@objc
protocol VisLifeCycleProtocol {
    func onDataSet()
    optional func onFocus()
    optional func onBlur()
}

class VisMasterViewController: UIViewController {
    
    var type: VisTypes!
    var json: JSON! {
        didSet {
            guard json != nil else {
                return
            }
            onDataSet()
        }
    }
    var chartData: [[String]] = [[String]]()
    var errorDescription: String! = nil {
        didSet {
            guard errorDescription != nil else {
                return
            }
            onErrorState()
        }
    }
    var searchText: String = ""
    var playBarController: PlayBarViewController!
    
    // UI
    var visHolderView: UIView!
    var activityIndicator: UIActivityIndicatorView!
    var messageLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(type: VisTypes) {
        super.init(nibName: nil, bundle: nil)
        
        self.type = type
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        visHolderView = UIView(frame: view.bounds)
        visHolderView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        visHolderView.backgroundColor = UIColor.clearColor()
        view.addSubview(visHolderView)
        visHolderView.hidden = true
        
        //Loading View
        activityIndicator = createActivityIndicatorView()
        view.addSubview(activityIndicator)
        addConstrainsToCenterInView(activityIndicator)
        
        //Results Label
        messageLabel = createUILabelForError()
        view.addSubview(messageLabel)
        addConstrainsToCenterInView(messageLabel)
    }
    
    func onDataSet() {
        Log("Override onDataSet")
    }
    
    func onFocus() {
        Log("Override onFocus")
    }
    
    func onBlur() {
        Log("Override onBlur")
    }
    
    // MARK: - Display states
    
    func onLoadingState() {
        visHolderView.hidden = true
        activityIndicator.startAnimating()
        activityIndicator.hidden = false
        messageLabel.hidden = true
    }
    
    func onSuccessState() {
        visHolderView.hidden = false
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
        messageLabel.hidden = true
    }
    
    func onNoDataState() {
        self.errorDescription = Config.noDataMessage
    }
    
    func onErrorState() {
        visHolderView.hidden = true
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
        messageLabel.text = errorDescription
        messageLabel.hidden = false
    }
    
    func clean() {
        errorDescription = nil
        json = nil
        onLoadingState()
    }
    
    
    // MARK: - UI Utils
    
    func createActivityIndicatorView() -> UIActivityIndicatorView
    {
        let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.frame = CGRectMake(0, 0, 100, 100);
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        activityIndicator.color = Config.darkBlueColor
        activityIndicator.startAnimating()
        activityIndicator.hidden = false
        
        return activityIndicator
    }
    
    func createUILabelForError() -> UILabel
    {
        let label = UILabel()
        label.frame = CGRectMake(0, 0, 300, 300);
        label.numberOfLines = 3
        label.textColor = Config.darkBlueColor
        label.text = Config.noDataMessage
        label.font = UIFont(name: "HelveticaNeue-Medium", size: 19)
        label.textAlignment = NSTextAlignment.Center
        label.hidden = true
        
        return label
    }
    
    func addConstrainsToCenterInView(viewToCenter: UIView) {
        let views = [
            "view": viewToCenter
        ]
        viewToCenter.translatesAutoresizingMaskIntoConstraints = false
        let viewConst_W = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: views)
        let viewConst_H = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: views)
        view.addConstraints(viewConst_W)
        view.addConstraints(viewConst_H)
    }
    
    // MARK: - Utils
    
    func returnArrayOfData(numberOfColumns: Int, containerName: String, json: JSON) -> Array<Array<String>>? {
        let col_cnt: Int? = numberOfColumns
        let row_cnt: Int? = json[containerName].array?.count
        
        if(row_cnt == nil || col_cnt == nil){
            errorDescription = Config.serverErrorMessage
            return nil
        }
        
        var tableData = Array(count: row_cnt!, repeatedValue: Array(count: col_cnt!, repeatedValue: ""))
        
        // populates the 2d array
        for (row, rowJson): (String, JSON) in json[containerName] {
            for (col, cellJson): (String, JSON) in rowJson {
                //println(row, col, cellJson)
                let r: Int = Int(row)!
                let c: Int = Int(col)!
                //self.tableData[r][c] = cellJson.stringValue
                //Log(cellJson.stringValue)
                
                tableData[r][c] = cellJson.stringValue.stringByReplacingOccurrencesOfString("\"", withString: "").stringByReplacingOccurrencesOfString("'", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "") //remove quotes
            }
        }
        return tableData
    }
}
