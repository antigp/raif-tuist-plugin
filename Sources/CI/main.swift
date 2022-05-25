//
//  File.swift
//  
//
//  Created by ANTROPOV Evgeny on 19.05.2022.
//

import Foundation
import RunShell

setbuf(__stdoutp, nil)
do {
    if !FileManager.default.fileExists(atPath: "./scripts/generator") {
        try? shell("git clone https://gitlabci.raiffeisen.ru/mobile_development/ios-kit/ios-flagship.git")
        try? shell("cp ./ios-flagship/Sources/generator scripts")
        try? shell("rm -rf ios-flagship")
    }
    if (try? shell("bundle check")) == nil {
        try shell("bundle install")
    }
    if (try? shell("pod repo list | grep \"https://artifactory.raiffeisen.ru/artifactory/api/pods/cocoapods\"") == nil) {
        try shell("pod repo-art add cocoapods-art \"https://artifactory.raiffeisen.ru/artifactory/api/pods/cocoapods\"")
    }
    try shell("./scripts/generator -e _Prebuild")
    try shell("tuist generate -n")
    try shell("CI_PIPELINE=TRUE TYPE=STATIC bundle exec pod install --repo-update")
} catch {
    fatalError(error.localizedDescription)
}


