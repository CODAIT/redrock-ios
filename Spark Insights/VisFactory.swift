//
//  VisFactory.swift
//  RedRock
//
//  Created by Jonathan Alter on 10/13/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import UIKit

class VisFactory {

    class func visualisationControllerForType(type: VisTypes) -> VisMasterViewController? {
        switch type {
        case .TreeMap, .CirclePacking, .ForceGraph, .StackedBar:
            return VisWebViewController(type: type)
        case .TimeMap:
            return VisNativeViewController(type: type)
        }
    }
}
