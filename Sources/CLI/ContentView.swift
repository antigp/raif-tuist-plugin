//
//  File.swift
//  
//
//  Created by ANTROPOV Evgeny on 19.05.2022.
//

import Foundation
import SwiftUI
import RunShell

@available(macOS 10.15, *)
struct ContentView: View {
    @StateObject var model = ContentViewModel()
    
    var body: some View {
        if model.credentionals != nil {
            VStack {
                HStack {
                    Picker("Config type", selection: $model.buildType) {
                        Text("With remote cache").tag(0)
                        Text("With all tests").tag(1)
                        Text("None").tag(2)
                        Text("Static").tag(3)
                    }
                    .pickerStyle(.segmented)
                }
                ScrollView {
                    ForEach($model.allPods) { pod in
                        HStack {
                            Toggle("is DevPod", isOn: pod.devPod)
                                .toggleStyle(.checkbox).frame(width: 80, alignment: .leading)
                            Text(pod.name.wrappedValue).frame(width: 150, alignment: .leading)
                            if pod.devPod.wrappedValue {
                                Text("Branch:").frame(width: 50, alignment: .leading)
                                TextField("", text: pod.branch).frame(width: 70, alignment: .leading)
                            } else {
                                Text("Version:").frame(width: 50, alignment: .leading)
                                TextField("", text: pod.version).frame(width: 70, alignment: .leading)
                            }
                        }.padding()
                    }
                }
                if model.isGenerating {
                    ProgressView("Project generating").progressViewStyle(.linear)
                } else {
                    Button {
                        model.generatePod()
                    } label: {
                        Text("Generate")
                    }
                }
            }.padding()
        } else {
            Text("Enter artifactory:").frame(width: 50, alignment: .leading)
            TextField("Login", text: $model.enteredLogin)
            SecureField("Password", text: $model.enteredPassword)
            Button {
                model.saveCredentionals()
            } label: {
                Text("Generate")
            }
        }
    }
}

class ContentViewModel: ObservableObject {
    @Published var buildType = 0
    @Published var allPods: [PodDependecy]
    @Published var isGenerating = false
    @Published var enteredLogin = ""
    @Published var enteredPassword = ""
    @Published var credentionals: (login: String, password: String)?
    var initialPods: [PodDependecy]
    var dependecyRawList: String
    
    init() {
        do {
            let pwd = FileManager.default.currentDirectoryPath
            dependecyRawList = try String(contentsOf: URL(fileURLWithPath: pwd + "/PodDeps/dependecy.rb"), encoding: .utf8)
            
            
            let nameRange = NSRange(
                dependecyRawList.startIndex..<dependecyRawList.endIndex,
                in: dependecyRawList
            )
            
            // Create A NSRegularExpression
            let capturePattern = #"pod_constructor :name => '([a-zA-Z0-9\.]*)',((?!pod_constructor).)*:dev_pod => (false|true)"#
            let captureRegex = try! NSRegularExpression(
                pattern: capturePattern,
                options: [.caseInsensitive, .dotMatchesLineSeparators]
            )
            
            // Find the matching capture groups
            let matches = captureRegex.matches(
                in: dependecyRawList,
                options: [],
                range: nameRange
            )
            
            guard matches.count != 0 else {
                // Handle exception
                throw "Failed to parse dependecy.rb"
            }
            
            var dependecies: [PodDependecy] = []
            for match in matches {
                let rawIndex = Range(match.range(at: 0), in: dependecyRawList)!
                let raw = dependecyRawList[rawIndex]
                let name = dependecyRawList[Range(match.range(at: 1), in: dependecyRawList)!]
                dependecies.append(
                    PodDependecy(
                        name: String(name),
                        rawData: raw.components(separatedBy: "\n"),
                        startLine: dependecyRawList.distance(from: dependecyRawList.startIndex, to: rawIndex.lowerBound),
                        endLine: dependecyRawList.distance(from: dependecyRawList.startIndex, to: rawIndex.upperBound)
                    )
                )
            }
            allPods = dependecies.sorted(by: {$0.name < $1.name })
            initialPods = dependecies.sorted(by: {$0.name < $1.name })
            credentionals = try? getSavedCredentionals()
        }
        catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func generatePod() {
        isGenerating = true
        let toUpdatePods = Array(Set(allPods).subtracting(Set(initialPods))).sorted(by: {$0.startLine > $1.startLine})
        var updatedPods = dependecyRawList
        for pod in toUpdatePods {
            updatedPods = updatedPods.replacingCharacters(in: updatedPods.index(updatedPods.startIndex, offsetBy: pod.startLine) ..< updatedPods.index(updatedPods.startIndex, offsetBy: pod.endLine), with: pod.generatedData)
        }
        let pwd = FileManager.default.currentDirectoryPath
        try! updatedPods.write(to: URL(fileURLWithPath: pwd + "/PodDeps/dependecy.rb"), atomically: true, encoding: .utf8)
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if !FileManager.default.fileExists(atPath: "./scripts/generator") {
                    try? shell("git clone https://gitlabci.raiffeisen.ru/mobile_development/ios-kit/ios-flagship.git")
                    try? shell("cp ./ios-flagship/Sources/generator scripts")
                    try? shell("rm -rf ios-flagship")
                }
                if (try? shell("bundle check")) == nil {
                    try shell("bundle install")
                }
                try shell("./scripts/generator -e _Prebuild")
                try shell("tuist generate -n")
                switch(self.buildType){
                case 0:
                    guard let credentionals = self.credentionals,!credentionals.login.isEmpty && !credentionals.password.isEmpty else { fatalError() }
                    print("Run Command: bundle exec pod binary fetch --repo-update")
                    try shell("ARTIFACTORY_LOGIN=\(credentionals.login) ARTIFACTORY_PASSWORD=\(credentionals.password) bundle exec pod binary fetch --repo-update", print: false)
                    try shell("bundle exec pod install")
                case 1:
                    try shell("rm -Rf _Prebuild")
                    try shell("rm -Rf _Prebuild_delta")
                    try shell("TYPE=TEST bundle exec pod install --repo-update")
                case 2:
                    try shell("rm -Rf _Prebuild")
                    try shell("rm -Rf _Prebuild_delta")
                    try shell("bundle exec pod install")
                default:
                    try shell("rm -Rf _Prebuild")
                    try shell("rm -Rf _Prebuild_delta")
                    try shell("TYPE=STATIC bundle exec pod install --repo-update")
                }
                try shell("open RMobile.xcworkspace")
            } catch {
                try! FileHandle.standardOutput.write(contentsOf: "Fatal error".data(using: .utf8)!)
                print("Fatal error")
                print(error.localizedDescription)
                NSApplication.shared.terminate(nil)
            }
            
            NSApplication.shared.terminate(nil)
        }
    }
    
    func saveCredentionals() {
        try? saveCredentionals(login: enteredLogin, password: enteredPassword)
        credentionals = (login: enteredLogin, password: enteredPassword)
    }
    
    private func saveCredentionals(login: String, password: String) throws {
        enum SaveError: Error {
            case unexpectedStatus(OSStatus)
        }
        let query: [String: AnyObject] = [
            // kSecAttrService,  kSecAttrAccount, and kSecClass
            // uniquely identify the item to save in Keychain
            kSecAttrService as String: "https://jira.raiffeisen.ru" as AnyObject,
            kSecAttrAccount as String: login as AnyObject,
            kSecClass as String: kSecClassInternetPassword,
            
            // kSecValueData is the item value to save
            kSecValueData as String: password as AnyObject
        ]
        
        // SecItemAdd attempts to add the item identified by
        // the query to keychain
        var status = SecItemAdd(
            query as CFDictionary,
            nil
        )

        // Update key, if exists
        if status == errSecDuplicateItem {
            let attributes: [String: AnyObject] = [
                   kSecValueData as String: password as AnyObject
            ]
            status = SecItemUpdate(
                  query as CFDictionary,
                  attributes as CFDictionary
            )
        }

        // Any status other than errSecSuccess indicates the
        // save operation failed.
        guard status == errSecSuccess else {
            throw SaveError.unexpectedStatus(status)
        }
        
    }
    
    private func getSavedCredentionals() throws -> (login: String, password: String)  {
        enum GettingError: Error {
            case itemNotFound
            case invalidItemFormat
            case unexpectedStatus(OSStatus)
        }
        let query: [String: AnyObject] = [
                kSecAttrService as String: "https://jira.raiffeisen.ru" as AnyObject,
                kSecClass as String: kSecClassInternetPassword,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecReturnData as String: kCFBooleanTrue,
                kSecReturnAttributes as String: kCFBooleanTrue
            ]

            // SecItemCopyMatching will attempt to copy the item
            // identified by query to the reference itemCopy
            var itemCopy: AnyObject?
            let status = SecItemCopyMatching(
                query as CFDictionary,
                &itemCopy
            )
        
        guard status != errSecItemNotFound else {
            throw GettingError.itemNotFound
        }

        guard status == errSecSuccess else {
            throw GettingError.unexpectedStatus(status)
        }
        
        guard let dic = itemCopy as? NSDictionary else {
            throw GettingError.invalidItemFormat
        }
        
        let username = (dic[kSecAttrAccount] as? String) ?? ""
        let passwordData = (dic[kSecValueData] as? Data) ?? Data()
        
        guard let password = String(data: passwordData, encoding: .utf8), !username.isEmpty else {
            throw GettingError.invalidItemFormat
        }
        
        return (login: username, password: password)
    }
}

struct PodDependecy: Identifiable, Equatable, Hashable {
    init(name: String, rawData: [String], startLine: Int, endLine: Int) {
        self.name = name
        self.startLine = startLine
        self.endLine = endLine
        self.components = rawData.reduce([String:String]()) { preResult, element in
            var result = preResult
            let components = element.components(separatedBy: "=>")
            guard let key = components.first, let value = components.last else {
                return preResult
            }
            result[key.trimmingCharacters(in: .whitespaces)] = value.components(separatedBy: "#").first?.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .init(charactersIn: "\",'"))
            return result
        }
    }
    var id: String { return name }
    var name: String
    var startLine: Int
    var endLine: Int
    private var components: [String: String]
    
    var devPod: Bool {
        get {
            return components[":dev_pod"] == "true"
        }
        set {
            components[":dev_pod"] = "\(newValue)"
        }
    }
    
    var branch: String {
        get {
            components[":branch"] ?? ""
        }
        set {
            components[":branch"] = "\(newValue)"
        }
    }
    
    var version: String {
        get {
            components[":version"] ?? ""
        }
        set {
            components[":version"] = "\(newValue)"
        }
    }
    
    var settings: String {
        get {
            components[":settings"] ?? "{}"
        }
        set {
            components[":settings"] = "\(newValue)"
        }
    }
    
    var localRepoPath: String {
        get {
            components[":local_repo_path"] ?? ""
        }
        set {
            components[":local_repo_path"] = "\(newValue)"
        }
    }
    
    var testSpecs: String {
        get {
            components[":testspecs"] ?? "[]"
        }
        set {
            components[":testspecs"] = "\(newValue)"
        }
    }
    
    var generatedData: String {
        return """
pod_constructor :name => '\(name)',
                    :version => '\(version)',
                    :settings => \(settings),
                    :branch => "\(branch)",
                    :testspecs => \(testSpecs),
                    :local_repo_path => '\(localRepoPath)',
                    :dev_pod => \(devPod)
"""
    }
}

extension String: Error {}
