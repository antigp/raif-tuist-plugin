//
//  File.swift
//  
//
//  Created by ANTROPOV Evgeny on 19.05.2022.
//

import Foundation

public func shell(_ command: String, print: Bool = true) throws {
    if print {
        Swift.print("Run command: \(command)")
    }
    enum Terminate: Error {
        case status(Int32)
    }
    let task = Process()
    
    let fileManager = FileManager.default
    var sourceRC = ""
    let homeDirURL = URL(fileURLWithPath: NSHomeDirectory()).path
    if fileManager.fileExists(atPath: "\(homeDirURL)/.bashrc") {
        sourceRC += "source \(homeDirURL)/.bashrc &&"
    }
    if fileManager.fileExists(atPath: "\(homeDirURL)/.zshrc") {
        sourceRC += "source \(homeDirURL)/.zshrc &&"
    }
    task.standardOutput = FileHandle.standardOutput
    task.standardError = FileHandle.standardError
    task.arguments = ["--login", "-c", "export HOME=\(homeDirURL) && export LANG=en_US.UTF-8 && \(sourceRC)" + command]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.environment = ["HOME": homeDirURL]
    task.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    task.launch()
    
    task.waitUntilExit()
    
    guard task.terminationStatus == 0 else {
        throw Terminate.status(task.terminationStatus)
    }
}
