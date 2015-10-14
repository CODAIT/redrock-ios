//
//  VisNativeViewController.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/13/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit

class VisNativeViewController: VisMasterViewController, VisLifeCycleProtocol {

    var countryCircleViews = [String: CircleView]()
    var timemapTimer : NSTimer!
    var indexOfLastDate = 0
    let maxCircleSize = 300.0
    var circleResizeConstant = 1.0 //this will change
    var timemapIsPlaying = true
    var mapView: TimeMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var mapTopPadding = 0.0
        if(CenterViewController.leftViewOpen){
            mapTopPadding = Config.smallscreenMapTopPadding
        }
        else{
            mapTopPadding = Config.fullscreenMapTopPadding
        }

        mapView = TimeMapView()

        let myMapView : UIImageView
        let image = UIImage(named: "robinsonmap.png")

        myMapView = UIImageView(frame: CGRectMake(0, CGFloat(mapTopPadding), view.frame.size.width, view.frame.size.height))
        myMapView.image = image
        
        // THE MAP
        mapView.addSubview(myMapView)
        mapView.baseMapView = myMapView
        
        visHolderView.addSubview(mapView)
        
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
        if self.chartData.count > 0 {
            self.timemapTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("tickTimemap"), userInfo: nil, repeats: true)
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
    
    func xFromCountryDictionary(myCountry: NSDictionary) -> Double{
        let longitude   = Double(myCountry["longitude"]! as! NSNumber)
        
        return xFromLongitude(longitude)
    }
    
    func yFromCountryDictionary(myCountry: NSDictionary) -> Double{
        let latitude    = Double(myCountry["latitude"]! as! NSNumber)
        
        return yFromLatitude(latitude)
    }
    
    func xForRobinson(myCountry: NSDictionary) -> Double{
        let x = Double(myCountry["x"]! as! NSNumber)*Double(self.view.bounds.size.height)
        return x
    }
    
    func yForRobinson(myCountry: NSDictionary) -> Double{
        let y = Double(myCountry["y"]! as! NSNumber)*Double(self.view.bounds.size.height)
        return y
    }
    
    func xFromLongitude(longitude: Double) -> Double{
        let mapWidth    = Double(view.bounds.width) // make it the map width?
        
        // get x value
        let x = (longitude+180.0)*(mapWidth/360.0)
        
        //Log("xFromLongitude... longitude: \(longitude) becomes x: \(x)")
        
        return x
    }
    
    func yFromLatitude(latitude: Double) -> Double{
        let mapWidth    = Double(view.bounds.width) // make it the map width?
        let mapHeight   = Double(view.bounds.height) // make it the map height?
        
        // ORIGINAL ASPECT RATIO //2058 × 1746
        // new aspect ratio // 1024 x 624
        let originalHeightAspect = 1746.0/2058.0 //badly hardcoded
        let newHeightAspect = Double(view.bounds.height/view.bounds.width)
        let resizeHeight = newHeightAspect/originalHeightAspect
        let resizedLatitude = resizeHeight*latitude
        
        
        // convert from degrees to radians
        let latRad = resizedLatitude*M_PI/180.0;
        
        // get y value
        let mercN = log(tan((M_PI/4.0)+(latRad/2.0)));
        let y     = (mapHeight/2.0)-(mapWidth*mercN/(2.0*M_PI));
        
        
        //Log("yFromLatitude... latitude: \(latitude) becomes y: \(y)")
        
        return y
    }
    
    func transformDataForTimemapIOS(){
        
        if(CenterViewController.leftViewOpen){ //small
            mapView.frame.origin.y = CGFloat(Config.smallscreenMapTopPadding)
        }
        else{ //big
            mapView.frame.origin.y = CGFloat(Config.fullscreenMapTopPadding)
        }
        
        mapView.baseMapView!.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
        
        //TODO only do this once
        var biggestValue = 0.0
        if self.chartData.count > 0
        {
            biggestValue = 0
            for r in 0..<self.chartData.count{
                
                let value = self.chartData[r][2]
                if(Double(value) > biggestValue){
                    biggestValue = Double(value)!
                }
            }
        }
        
        circleResizeConstant = maxCircleSize / biggestValue //size of the biggest possible circle
        
        //Log("map size in transformDataForTimemapIOS... scrollViewWidth.. \(scrollViewWidth),  scrollViewHeight.. \(scrollViewHeight)");
        //let filePath = NSBundle.mainBundle().pathForResource("VisualizationsNativeData/timemap/CountryData", ofType: "plist")
        //let properties = NSDictionary(contentsOfFile: filePath!)
        
        let robinsonProperties = NSDictionary(contentsOfFile: NSBundle.mainBundle().pathForResource("VisualizationsNativeData/timemap/countrypositions5", ofType: "plist")!)
        
        let countriesFilePath = NSBundle.mainBundle().pathForResource("VisualizationsNativeData/timemap/CountryList", ofType: "plist")
        let countries = NSDictionary(contentsOfFile: countriesFilePath!)
        
        let countriesArray : Array = countries?.objectForKey("CountryList") as! Array<String>
        
        zeroTimemapCircles()
        countryCircleViews.removeAll()
        if(countryCircleViews.isEmpty){ //initialize it if you havent //this isnt being redone! redo it
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
    
    @objc func tickTimemap()
    {
        //Log("tickTimemap().... indexOfLastDate is \(indexOfLastDate)")
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
        
        while( currentDate == lastDate){ // and you're not at the end
            
            var radius : CGFloat = 0.0
            
            if let n = NSNumberFormatter().numberFromString(chartData[i][2]) {
                radius = CGFloat(n) * CGFloat(circleResizeConstant)
            }
            
            //change the radius associated with the string
            countryCircleViews[chartData[i][1]]?.changeRadiusTo(radius)
            
            lastDate = chartData[i][0]
            i++
            if( i >= chartData.count ){
                //Log("Reached the end of timemap data.... it's time to loop.")
                i = 0
            }
            currentDate = chartData[i][0]
        }
        
        let dateStringFormatter = NSDateFormatter()
        dateStringFormatter.dateFormat = "yyyy MM/dd HH"
        dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        // Aug 10 07
        // TODO playing with fire, as soon as the year rolls over this breaks
        // the dates from backend need to be explicit!!
        let firstDateString = "2015 "+chartData[0][0]
        let finalDateString = "2015 "+chartData[chartData.count-1][0]
        let lastDateString = "2015 "+lastDate
        
        let firstDateForMath = dateStringFormatter.dateFromString(firstDateString)
        let finalDateForMath = dateStringFormatter.dateFromString(finalDateString)
        let lastDateForMath = dateStringFormatter.dateFromString(lastDateString)
        
        //Log("firstDateForMath... \(firstDateForMath)")
        //Log("finalDateForMath... \(finalDateForMath)")
        //Log("lastDateForMath... \(lastDateForMath)")
        
        let playBarViewControllerProgress = ((lastDateForMath?.timeIntervalSince1970)!-(firstDateForMath?.timeIntervalSince1970)!)/((finalDateForMath?.timeIntervalSince1970)!-(firstDateForMath?.timeIntervalSince1970)!)
        
        self.playBarController?.progress = Float(playBarViewControllerProgress)*100
        
        //Log("playBarViewControllerProgress... \(playBarViewControllerProgress)")
        
        indexOfLastDate = i
        self.view.setNeedsDisplay()
    }

}
