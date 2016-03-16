//
//  VisMasterViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/12/15.
//

/**
* (C) Copyright IBM Corp. 2015, 2015
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
*/

import UIKit

enum VisTypes {
    case TreeMap
    case CirclePacking
    case ForceGraph
    case StackedBar
    case StackedBarDrilldownCirclePacking
    case TimeMap
    case SidewaysBar
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
            
            switch Config.appState {
            case .Historic:
                onDataSet()
            case .Live:
                guard oldValue != nil else {
                    onDataSet()
                    break
                }
                // Skip reloading the webview
                transformData()
            }
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
    
    var visHolderChildren = [VisHolderViewController]()
    
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
    
    func transformData() {
        Log("Override transformData")
    }
    
    // MARK: - Display states
    
    func onLoadingState() {
        hideWithAnimation()
        activityIndicator.startAnimating()
        activityIndicator.hidden = false
        messageLabel.hidden = true
    }
    
    func onSuccessState() {
        revealWithAnimation()
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
        messageLabel.hidden = true
    }
    
    func onNoDataState() {
        self.errorDescription = Config.noDataMessage
    }
    
    func onErrorState() {
        hideWithAnimation()
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
        messageLabel.text = errorDescription
        messageLabel.hidden = false
    }
    
    func onHiddenState() {
        hideWithAnimation()
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
        messageLabel.hidden = true
    }
    
    func hideWithAnimation() {
        UIView.animateWithDuration(0.1, animations: {
            self.visHolderView.alpha = 0.0
            }, completion: { finished in
                self.visHolderView.hidden = true
        }) //bad access error?
    }
    
    func revealWithAnimation() {
        self.visHolderView.hidden = false
        UIView.animateWithDuration(1.0, animations: {
            self.visHolderView.alpha = 1.0
            }, completion: { finished in
                self.visHolderView.hidden = false
        })
    }
    
    
    func clean() {
        errorDescription = nil
        json = nil
        onLoadingState()
        removeAllVisHolderChildren()
    }
    
    func addVisHolderController(vc: VisHolderViewController) {
        addChildViewController(vc)
        visHolderView.addSubview(vc.view)
        vc.didMoveToParentViewController(self)
        visHolderChildren.append(vc)
        
        addConstrainsToCenterInView(vc.view)
    }
    
    func removeAllVisHolderChildren() {
        for vh in visHolderChildren {
            vh.removeView()
        }
        visHolderChildren.removeAll()
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
    
    //TODO -- WRITE A DIFFERENT FUNCTION FOR UNWRAPPING THE LIVE DATA
    func returnArrayOfLiveData(numberOfColumns: Int, containerName: String, json: JSON) -> Array<Array<String>>? {
        
        //Log("returnArrayOfData... numberOfColumns: \(numberOfColumns)... containerName: \(containerName)...")
        //print(json)
        
        let col_cnt: Int? = numberOfColumns
        let row_cnt: Int? = json.array?.count
        
        //Log("col_cnt: \(col_cnt)... row_cnt: \(row_cnt)")

        if(row_cnt == nil || col_cnt == nil){
            //Log("row_cnt == nil || col_cnt == nil")
            errorDescription = Config.serverErrorMessage
            return nil
        }
        
        var tableData = Array(count: row_cnt!, repeatedValue: Array(count: col_cnt!, repeatedValue: ""))
        
        // populates the 2d array
        for (row, rowJson): (String, JSON) in json {
            for (col, cellJson): (String, JSON) in rowJson {
                //print(row, col, cellJson)
                let r: Int = Int(row)!
                let c: Int = Int(col)!
                //self.tableData[r][c] = cellJson.stringValue
                //Log(cellJson.stringValue)
                
                tableData[r][c] = cellJson.stringValue.stringByReplacingOccurrencesOfString("\"", withString: "").stringByReplacingOccurrencesOfString("'", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "") //remove quotes
            }
        }
        
        //Log("tableData")
        //Log(tableData)
        
        return tableData
        
    }
    
    
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
                let r: Int = Int(row)!
                let c: Int = Int(col)!
                
                tableData[r][c] = cellJson.stringValue.stringByReplacingOccurrencesOfString("\"", withString: "").stringByReplacingOccurrencesOfString("'", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "") //remove quotes
            }
        }

        return tableData
    }
}
