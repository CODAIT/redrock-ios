//
//  AppDelegate.swift
//  Spark Insights
//
//  Created by Jonathan Alter on 5/27/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SearchViewControllerDelegate, ContainerViewControllerDelegate {

    var window: UIWindow?
    var storyboard: UIStoryboard?
    var containerViewController: ContainerViewController?
    var searchViewController: SearchViewController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        displaySearchViewController()
        if Config.skipSearchScreen {
            displayContainerViewController(searchViewController!, searchText: "")
        }
        
        /*
        NOTE: Copying Visualisations folder to '/tmp/www' to work around an issue with
        loading the files from the bundle. Without this workaround WKNetworkDelegate methods
        will not be called and we will get the following error "Could not create a sandbox extension for /".
        */
        let visFolder = NSBundle.mainBundle().resourcePath?.stringByAppendingPathComponent("Visualizations")
        Config.visualisationFolderPath = copyFolderToTempFolder(visFolder)!
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

// MARK: - SearchViewControllerDelegate

extension AppDelegate: SearchViewControllerDelegate {
    
    func displayContainerViewController(currentViewController: UIViewController, searchText: String) {
        if (containerViewController == nil) {
            containerViewController = ContainerViewController()
            containerViewController!.delegate = self
        }
        else
        {
            containerViewController!.centerViewController.searchText = searchText
        }
        containerViewController!.searchText = searchText
        
        // Animate the transition to the new view controller
        var tr = CATransition()
        tr.duration = 0.5
        tr.type = kCATransitionFade
        currentViewController.view.window!.layer.addAnimation(tr, forKey: kCATransition)
        currentViewController.presentViewController(containerViewController!, animated: false, completion: nil)
    }
    
}

// MARK: - ContainerViewControllerDelegate

extension AppDelegate: ContainerViewControllerDelegate {
    
    func displaySearchViewController() {
        // On first launch
        if (searchViewController == nil) {
            searchViewController = storyboard!.instantiateViewControllerWithIdentifier("SearchViewController") as? SearchViewController
            searchViewController!.delegate = self
            
            self.window!.rootViewController = searchViewController
            self.window!.makeKeyAndVisible()
        }
        else
        {
            searchViewController?.recalculateConstrainstForBakcAnimation()
        }
        
        // When returning to search
        if (containerViewController != nil) {
            // Animate the transition to the new view controller
            var tr = CATransition()
            tr.duration = 0.2
            tr.type = kCATransitionFade
            containerViewController?.view.window!.layer.addAnimation(tr, forKey: kCATransition)
            containerViewController?.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
}

// MARK: Utils

func copyFolderToTempFolder(filePath: String?) -> String?
{
    let fileMgr = NSFileManager.defaultManager()
    let tmpPath = NSTemporaryDirectory().stringByAppendingPathComponent("www")
    var error: NSErrorPointer = nil
    if !fileMgr.createDirectoryAtPath(tmpPath, withIntermediateDirectories: true, attributes: nil, error: error) {
        println("Couldn't create www subdirectory. \(error)")
        return nil
    }
    let destPath = tmpPath
    // Clean up old files
    if fileMgr.fileExistsAtPath(destPath) {
        if !fileMgr.removeItemAtPath(destPath, error: error) {
            println("Couldn't delete folder /tmp/www. \(error)")
        }
    }
    // Copy files to temp dir
    if !fileMgr.fileExistsAtPath(destPath) {
        if !fileMgr.copyItemAtPath(filePath!, toPath: destPath, error: error) {
            println("Couldn't copy file to /tmp/www. \(error)")
            return nil
        }
    }
    return destPath
}
