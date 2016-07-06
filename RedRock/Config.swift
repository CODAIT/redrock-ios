//
//  Config.swift
//  Spark Insights
//
//  Created by Jonathan Alter on 5/29/15.
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

enum AppStates {
    case Historic
    case Live
}

enum SentimentTypes: Int {
    case Positive
    case Negative
}

class Config {
    static let loginKeyForNSUserDefaults = "login"
    
    static let skipSearchScreen = false // Default: false
    static let useDummyData = false // Default: false
    static let dummyDataDelay = 1.0 // Seconds
    static let searchViewAnimation = true // Default: true
    static let serverMakeSingleRequest = true
    static let displayRequestTimer = false //Default: false
    static let displayRefreshAvailable = false //enable refresh for streaming data
    static let validateEmailAccess = false // If true, the login email will be checked for access auth on the RR server
    
    // MARK: - Server
    static let serverAddress = "http://localhost:16666" // Localhost
    static let serverSearch = "ss/search" // Includes all responses in one
    static let serverPowertrackWordcount = "ss/powertrack/wordcount"
    static let serverSentimentAnalysis = "ss/sentiment/analysis"
    static let serverTweetsPath = "ss/toptweets"
    static let serverSentimentPath = "ss/sentiment"
    static let serverLocationPath = "ss/location"
    static let serverProfessionPath = "ss/profession"
    static let serverWorddistancePath = "ss/distance"
    static let serverWordclusterPath = "ss/cluster"
    static let serverWordcloudPath = "ss/topic"
    static let serverLogin = "ss/auth/signin"
    static let serverLogout = "ss/auth/signout"
    static let tweetsTopParameter = "100"
    static let wordDistanceTopParameter = "20"
    static let wordClusterClusterParameter = "5"
    static let wordClusterWordParameter = "3"
    static var userName: String?
    static var userNameEncoded: String? {
        get {
            return userName!.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        }
    }
    
    // MARK: - Server Live
    static let liveBatchSize = "60" // timeline in minutes to be consider at the search (startDate = date now - batchSize, endDate = date now)
    static let liveTopTweets = "100" // amount of tweets to be returned
    static let liveTopWords = "10" // amount of counted words to be returned
    static let liveSearches = ["#IBMInsight", "#SparkInsight", "#SparkSummit"]
    static var liveCurrentSearchIndex =  0

    // MARK: - Jury-Rigged Websocket
    static let networkTimerInterval = 5.0 //seconds
    
    // MARK: - Colors
    static let tealColor = UIColor(rgba: "#00B4A0") // Teal
    static let darkBlueColor = UIColor(rgba: "#1C3648") // Dark Blue
    static let extraDarkBlueColor = UIColor(rgba: "##111E28") // Extra Dark Blue
    static let lightGrayColor = UIColor(rgba: "#ECF0F1") // Light Gray
    static let darkOrange = UIColor(rgba: "#F05222")
    static let lightSeaGreen = UIColor(rgba: "#00B39F")
    static let mediumGreen = UIColor(rgba: "#6CB444")
    static let lightWhiteIce = UIColor(rgba: "#f9f9fb")
    static let mapBackgroundColor = UIColor(rgba: "#325D80")

    // MARK: Colors V2
    static let darkBlueColorV2 = UIColor(rgba: "#263a60")
    static let lightBlueTextColorV2 = UIColor(rgba: "#86c3ea")
    static let superLightBlueTextColorV2 = UIColor(rgba: "#dee8e8")

    // MARK: Text colors
    static let darkGrayTextColor = UIColor(rgba: "#5A6464") // Dark Gray Text
    static let lightGrayTextColor = UIColor(rgba: "#AEB8B8") // Light Gray Text
    static let greenTextColor = UIColor(rgba: "#8EC63E") // Green Text (142,198,62)
    static let redTextColor = UIColor(rgba: "#F05253") // Red Text (240,82,83)

    // MARK: Tweets
    static let tweetsTableBackgroundColor = darkBlueColor
    static let tweetsProfileImageBorderColor = darkOrange
    static let tweetsTableTextComponentsColor = lightSeaGreen
    
    static let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z"
    static let dateFormatMonthDay = "M/d"

    // MARK: Side Search
    static let sideSearchTextFieldColor = extraDarkBlueColor
    static let sideSearchTextFieldPlaceholderColor = lightGrayTextColor

    // MARK: Settings Historic
    
    static let visualizationTypesHistoric: [VisTypes] = [.CirclePacking, .StackedBar, .TreeMap, .TimeMap, .ForceGraph]
    static let visualizationButtonsHistoric         = ["RR2.0_Bubble_Blue", "RR2.0_Bar_Blue","RR2.0_Tree_Blue", "RR2.0_Map_Blue", "RR2.0_Network_Blue"]
    static let visualizationButtonsSelectedHistoric = ["RR2.0_Bubble_WHITE", "RR2.0_Bar_WHITE", "RR2.0_Tree_WHITE", "RR2.0_Map_WHITE", "RR2.0_Network_WHITE"]
    static let visualizationTitlesHistoric          = ["Bubble Chart - Relationships", "Bar Chart - Sentiment", "Treemap - Tweeter Careers", "World Map - Frequency","Network Graph - Related Words"]
    
    static let visualizationDescriptionHistoric = [
        "Shows relationships between different elements. Size indicates number of occurances and colored grouping represent different categories.",
        "Shows the overal positive and negative sentiment for the given search.",
        "Display the number of top users grouped according to profession.",
        "Represents the volume of related tweets by location over time.",
        "Shows the closest words to the searched term, and the size of the circle represents its frequency."
    ]
    
    static let visualizationDrawerStatesHistoric: [VisTypes: BottomDrawerState] = [
        VisTypes.CirclePacking: BottomDrawerState.ClosedFully,
        VisTypes.StackedBar: BottomDrawerState.ClosedPartial,
        VisTypes.TreeMap: BottomDrawerState.ClosedFully,
        VisTypes.TimeMap: BottomDrawerState.ClosedPartial,
        VisTypes.ForceGraph: BottomDrawerState.ClosedFully
    ]
    
    // MARK: Settings Live
    
    static let visualizationTypesLive: [VisTypes] = [.SidewaysBar]
    static let visualizationButtonsLive         = ["RR2.0_Bar_Blue"]
    static let visualizationButtonsSelectedLive = ["RR2.0_Bar_WHITE"]
    static let visualizationTitlesLive          = ["Word Count - Count of top words tweeted"]
    
    static let visualizationDescriptionLive = [
        "Shows the top words tweeted over the past hour for the filter."
    ]
    
    static let visualizationDrawerStatesLive: [VisTypes: BottomDrawerState] = [
        VisTypes.SidewaysBar: BottomDrawerState.ClosedFully
    ]
    
    // MARK: Settings Holders
    
    // visualizationButtons and visualizationButtonsSelected need to manually match
    static var visualizationTypes: [VisTypes] = []
    static var visualizationButtons: [String] = []
    static var visualizationButtonsSelected: [String] = []
    static var visualizationTitles: [String]          = []

    static var visualizationDescription: [String] = []

    static var visualizationDrawerStates: [VisTypes: BottomDrawerState] = Dictionary()
    
    static var appState = AppStates.Historic {
        didSet {
            switch appState {
            case .Historic:
                visualizationTypes              = visualizationTypesHistoric
                visualizationButtons            = visualizationButtonsHistoric
                visualizationButtonsSelected    = visualizationButtonsSelectedHistoric
                visualizationTitles             = visualizationTitlesHistoric
                visualizationDescription        = visualizationDescriptionHistoric
                visualizationDrawerStates       = visualizationDrawerStatesHistoric
            case .Live:
                visualizationTypes              = visualizationTypesLive
                visualizationButtons            = visualizationButtonsLive
                visualizationButtonsSelected    = visualizationButtonsSelectedLive
                visualizationTitles             = visualizationTitlesLive
                visualizationDescription        = visualizationDescriptionLive
                visualizationDrawerStates       = visualizationDrawerStatesLive
            }
        }
    }
    
    // MARK: Strings
    static let loginAlertTitle = "Please enter your IBM email"
    static let loginAlertMessage = "You must login to use RedRock"
    static let loginDefaultText = ""
    static let loginPleaseLogin = " Please login "
    static let redrockPassword = "bigbear"
    
    // MARK: Vis settings
    
    static let fullscreenMapTopPadding = 25.0
    static let smallscreenMapTopPadding = 120.0
    static let fullscreenMapVerticalScaleConstant = 0.8
    static let smallscreenMapVerticalScaleConstant = 0.55
    static let maxCircleSize = 300.0
    
    static let timemapTimeIntervalInSeconds = 0.5
    
    static let dateRangeIntervalForStackedbarDrilldownInSeconds = 60*60*24 //one hour is 60 minutes, 1 minute is 60 seconds //one day is 60*60*24 seconds
    // BARBARA this is the only variable that needs to change for day/hour i think
    
    static let noDataMessage = "No data available"
    static let serverErrorMessage = "Server error. Request failed"

    static func getNumberOfVisualizations()->Int{
        return self.visualizationTypes.count;
    }

    // MARK: global variables
    static var visualizationFolderPath = "" // Holds the path to the visualizations folder, will be initialized at app startup
}
