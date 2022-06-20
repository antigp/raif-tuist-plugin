//
//  File.swift
//  
//
//  Created by ANTROPOV Evgeny on 19.05.2022.
//

import Foundation

public var defaultShell: String?
@discardableResult
public func shell(_ command: String, print: Bool = true, shell: String? = defaultShell) throws -> String {
    let homeDirURL = URL(fileURLWithPath: NSHomeDirectory())    
    var runShell = shell
    if runShell == nil {
        runShell = try shellWithResult("dscl . -read \(homeDirURL.path) UserShell | sed 's/UserShell: //'").trimmingCharacters(in: .whitespacesAndNewlines)
        switch(runShell){
        case "/bin/zsh", "/bin/bash":
            ()
        default:
            runShell = "/bin/bash"
        }
        defaultShell = runShell
        Swift.print("Select shell: \(runShell ?? "None")")
    }
    if print {
        Swift.print("Run command: \(command)")
    }
    enum Terminate: Error {
        case status(Int32)
    }
    let task = Process()
    let pipe = Pipe()

    let fileManager = FileManager.default
    var sourceRC = ""
    if runShell == "/bin/bash" {
        if fileManager.fileExists(atPath: "\(homeDirURL.path)/.bashrc") {
            sourceRC += "source \(homeDirURL.path)/.bashrc &&"
        }
    }
    if runShell == "/bin/zsh" {
        if fileManager.fileExists(atPath: "\(homeDirURL.path)/.zshrc") {
            sourceRC += "source \(homeDirURL.path)/.zshrc &&"
        }
    }
    task.standardOutput = pipe
    task.standardError = pipe
    task.standardInput = FileHandle.standardInput
    task.arguments = ["--login", "-c", "export HOME=\(homeDirURL.path) && export LANG=en_US.UTF-8 && \(sourceRC)" + command]
    task.launchPath = runShell
    task.environment = ["HOME": homeDirURL.path]
    task.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    
    var result = ""
    NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: pipe.fileHandleForReading , queue: nil) { notification in
        let output = pipe.fileHandleForReading.availableData
        let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
        Swift.print(outputString, terminator: "")
        result += outputString
        pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }

    pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    task.launch()
    task.waitUntilExit()
    
    guard task.terminationStatus == 0 else {
        throw Terminate.status(task.terminationStatus)
    }
    
    return result
}

fileprivate func shellWithResult(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.standardInput = nil

    try task.run()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}
