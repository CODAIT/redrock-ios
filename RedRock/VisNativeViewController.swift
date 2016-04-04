//
//  VisNativeViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/13/15.
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

class VisNativeViewController: VisMasterViewController, VisLifeCycleProtocol {

    var countryCircleViews = [String: CircleView]()
    var timemapTimer : NSTimer!
    var indexOfLastDate = 0
    var circleResizeConstant : Double = 1.0 //this will change from this value, just a default value
    var timemapIsPlaying = true
    var timemapDataIsInvalid = false
    var mapView: TimeMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.clipsToBounds = true

        var mapTopPadding = 0.0
        if(CenterViewController.leftViewOpen){
            mapTopPadding = Config.smallscreenMapTopPadding
        }
        else{
            mapTopPadding = Config.fullscreenMapTopPadding
        }

        mapView = TimeMapView()

        let myMapView : UIImageView
        let image = UIImage(named: "robinsonmap_for_coordinates_clear_2.png")

        myMapView = UIImageView(frame: CGRectMake(0, CGFloat(mapTopPadding), view.frame.size.width, view.frame.size.height))
        myMapView.image = image
        
        // THE MAP
        mapView.addSubview(myMapView)
        mapView.baseMapView = myMapView
        
        visHolderView.addSubview(mapView)
        
        visHolderView.backgroundColor = Config.mapBackgroundColor
        
        if json != nil {
            transformDataForTimemapIOS()
        }
    }

    override func onDataSet() {
        onLoadingState()
        
        let numberOfColumns = 3        // number of columns
        let containerName = "location" // name of container for data //TODO: unknown
        
        var contentJson = json
        if contentJson != nil
        {
            contentJson = json![containerName]
            if contentJson != nil
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    let data = self.returnArrayOfData(numberOfColumns, containerName: containerName, json: contentJson!)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if(data != nil){
                            self.chartData = data!
                            if self.isViewLoaded() {
                                self.transformDataForTimemapIOS()
                            }
                            self.onSuccessState()
                            
                            if self.playBarController.state == .Playing {
                                self.startTimemap()
                            }
                        }
                        else{
                            self.errorDescription = Config.serverErrorMessage
                        }
                    })
                })
                return
            }
            self.errorDescription = Config.serverErrorMessage
        }
        
        self.errorDescription = Config.serverErrorMessage
    }
    
    override func onFocus() {
        startTimemap()
        playBarController.state = .Playing
    }
    
    override func onBlur() {
        stopTimemap()
        zeroTimemapCircles()
        playBarController.state = .Paused
    }
    
    override func clean() {
        stopTimemap()
        super.clean()
    }
    
    func stopTimemap(){
        self.timemapIsPlaying = false
        invalidateTimer()
        
    }
    
    func startTimemap(){
        self.timemapIsPlaying = true
        
        invalidateTimer()
        
        if self.chartData.count > 1 && !timemapDataIsInvalid {
            self.timemapTimer = NSTimer.scheduledTimerWithTimeInterval(Config.timemapTimeIntervalInSeconds, target: self, selector: Selector("tickTimemap"), userInfo: nil, repeats: true)
        }
        else{
            Log("timemapdata is not greater than 1")
        }
    }
    
    func invalidateTimer() {
        if timemapTimer != nil {
            timemapTimer.invalidate()
            timemapTimer = nil;
        }
    }
    
    // todo perhaps make the circles invisible too
    func zeroTimemapCircles(){
        let countriesFilePath = NSBundle.mainBundle().pathForResource("VisualizationsNativeData/timemap/CountryList", ofType: "plist")
        let countries = NSDictionary(contentsOfFile: countriesFilePath!)
        
        let countriesArray : Array = countries?.objectForKey("CountryList") as! Array<String>
        if !countryCircleViews.isEmpty{
            for myCountryString in countriesArray{
                countryCircleViews[myCountryString]?.changeRadiusTo(0.0)
            }
        }
    }
    
    func xForRobinson(myCountry: NSDictionary) -> Double{
        let x = Double(myCountry["x"]! as! NSNumber)*Double(mapView.baseMapView!.frame.width)
        return x
    }
    
    func yForRobinson(myCountry: NSDictionary) -> Double{
        let y = Double(myCountry["y"]! as! NSNumber)*Double(mapView.baseMapView!.frame.height)
        return y
    }
    
    func transformDataForTimemapIOS(){
        
        timemapDataIsInvalid = false
        indexOfLastDate = 0

        var mapVerticalScaleConstant = 1.0
        if(CenterViewController.leftViewOpen){ //small
            mapView.frame.origin.y = CGFloat(Config.smallscreenMapTopPadding)
            mapVerticalScaleConstant = Config.smallscreenMapVerticalScaleConstant
        }
        else{ //big
            mapView.frame.origin.y = CGFloat(Config.fullscreenMapTopPadding)
            mapVerticalScaleConstant = Config.fullscreenMapVerticalScaleConstant
        }
        
        mapView.baseMapView!.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height*CGFloat(mapVerticalScaleConstant))
        
        var biggestValue = 0.0
        if self.chartData.count > 1
        {
            biggestValue = 0
            for r in 0..<self.chartData.count{
                let value = self.chartData[r][2]
                if(Double(value) > biggestValue){
                    biggestValue = Double(value)!
                }
            }
        }
        
        
        circleResizeConstant = Config.maxCircleSize * mapVerticalScaleConstant / biggestValue //size of the biggest possible circle
        
        let robinsonProperties = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("VisualizationsNativeData/timemap/countrypositions5", ofType: "plist")!)
        
        let countriesFilePath = NSBundle.mainBundle().pathForResource("VisualizationsNativeData/timemap/CountryList", ofType: "plist")
        let countries = NSDictionary(contentsOfFile: countriesFilePath!)
        
        let countriesArray : Array = countries?.objectForKey("CountryList") as! Array<String>
        
        zeroTimemapCircles()
        countryCircleViews.removeAll()
        if(countryCircleViews.isEmpty){ //initialize it if you havent
            for myCountryString in countriesArray{
                
                let myCountry : NSDictionary = robinsonProperties![myCountryString]! as! NSDictionary
                
                let x = xForRobinson(myCountry)
                let y = yForRobinson(myCountry)
                
                var circleView : CircleView
                circleView = CircleView(frame: CGRectMake( CGFloat(x), CGFloat(y), 0, 0))
                
                countryCircleViews[myCountryString] = circleView
                
                mapView.addSubview(circleView)
            }
        }
    }
    
    func convertDateStringToIntervalSince1970(myDateString : String) -> Double{
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = Config.dateFormat
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        let dateForMath = dateStringFormatter.dateFromString(myDateString)
        return (dateForMath?.timeIntervalSince1970)!
    }
    
    func setTimemapDateBasedOnPercentageProgressOfBarUsingGuess(barProgress: Double)
    {
        // just guess the index based on the ratio
        let index : Int = Int(round(barProgress * Double(chartData.count)))
        indexOfLastDate = (index >= chartData.count) ? chartData.count - 1 : index
        
        tickTimemap()
        tickTimemap()
    }
    
    @objc func tickTimemap()
    {
        let countriesFilePath = NSBundle.mainBundle().pathForResource("VisualizationsNativeData/timemap/CountryList", ofType: "plist")
        let countries = NSDictionary(contentsOfFile: countriesFilePath!)
        let countriesArray : Array = countries?.objectForKey("CountryList") as! Array<String>
        
        for countryName in countriesArray
        {
            if let myCircleView = countryCircleViews[countryName] {
                myCircleView.changeRadiusTo(0.0)
            }
        }
        
        // set the radii
        var lastDate :String = "";
        var currentDate :String = "";
        var i = indexOfLastDate;
        
        while( currentDate == lastDate && !timemapDataIsInvalid){ // and you're not at the end
            
            var radius : CGFloat = 0.0
            
            if let n = NSNumberFormatter().numberFromString(chartData[i][2]) {
                radius = CGFloat(n) * CGFloat(circleResizeConstant)
            }
            
            //change the radius associated with the string
            countryCircleViews[chartData[i][1]]?.changeRadiusTo(radius)
            
            lastDate = chartData[i][0]
            i++
            if( i >= chartData.count ){
                i = 0
                currentDate = chartData[i][0]
                if lastDate == currentDate {
                    //Log("this dataset doesn't have more than one date!")
                    //break out
                    timemapDataIsInvalid = true
                }
            }
            currentDate = chartData[i][0]
        }
        
        if(!timemapDataIsInvalid){
            let dateStringFormatter = NSDateFormatter()
            
            dateStringFormatter.dateFormat = Config.dateFormat
            
            dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            
            let firstDateString = chartData[0][0]
            let finalDateString = chartData[chartData.count-1][0]
            let lastDateString = lastDate
            
            let firstDateForMath = dateStringFormatter.dateFromString(firstDateString)
            let finalDateForMath = dateStringFormatter.dateFromString(finalDateString)
            let lastDateForMath = dateStringFormatter.dateFromString(lastDateString)
        
            let playBarViewControllerProgress = ((lastDateForMath?.timeIntervalSince1970)!-(firstDateForMath?.timeIntervalSince1970)!)/((finalDateForMath?.timeIntervalSince1970)!-(firstDateForMath?.timeIntervalSince1970)!)
            
            self.playBarController?.progress = Float(playBarViewControllerProgress)*100
            self.playBarController?.date = dateStringFormatter.dateFromString(currentDate)!
        }
        
        indexOfLastDate = i
        self.view.setNeedsDisplay()
    }

}
