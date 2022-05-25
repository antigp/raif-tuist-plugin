//
//  File.swift
//  
//
//  Created by ANTROPOV Evgeny on 19.05.2022.
//

import Foundation

public var defaultShell: String?
public func shell(_ command: String, print: Bool = true, shell: String? = defaultShell) throws {
    let homeDirURL = URL(fileURLWithPath: NSHomeDirectory())    
    var runShell = shell
    if runShell == nil {
        runShell = try shellWithResult("dscl . -read /Users/\(homeDirURL.lastPathComponent) UserShell | sed 's/UserShell: //'").trimmingCharacters(in: .whitespacesAndNewlines)
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
    task.standardOutput = FileHandle.standardOutput
    task.standardError = FileHandle.standardError
    task.arguments = ["--login", "-c", "export HOME=\(homeDirURL.path) && export LANG=en_US.UTF-8 && \(sourceRC)" + command]
    task.launchPath = runShell
    task.standardInput = nil
    task.environment = ["HOME": homeDirURL.path]
    task.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    task.launch()
    
    task.waitUntilExit()
    
    guard task.terminationStatus == 0 else {
        throw Terminate.status(task.terminationStatus)
    }
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
