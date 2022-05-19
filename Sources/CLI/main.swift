//
//  File.swift
//  
//
//  Created by ANTROPOV Evgeny on 19.05.2022.
//

import AppKit
import Foundation
import CommandLineKit
import RunShell

setbuf(__stdoutp, nil)
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
