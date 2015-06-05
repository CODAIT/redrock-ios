//
//  Log.swift
//  RedRock
//
//  Created by Jonathan Alter on 6/5/15.
//  Copyright (c) 2015 IBM. All rights reserved.
//

import Foundation

func Log(msg: AnyObject) {
    #if DEBUGLOG
        println(msg)
    #endif
}
