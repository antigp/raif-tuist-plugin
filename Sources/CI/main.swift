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
    let homeDirURL = URL(fileURLWithPath: NSHomeDirectory())
    if (
        (try? shell("bundle exec pod repo-art list | grep cocoapods-art")) == nil ||
        !FileManager.default.fileExists(atPath: "\(homeDirURL.path)/.cocoapods/repos-art/cocoapods-art/.artpodrc")
    ) {
        try? shell("bundle exec pod repo-art remove cocoapods-art")
        try shell("bundle exec pod repo-art add cocoapods-art \"https://artifactory.raiffeisen.ru/artifactory/api/pods/cocoapods\"")
    } else {
        try shell("bundle exec pod repo-art update cocoapods-art")
    }
        
    try shell("./scripts/generator -e _Prebuild")
    try shell("tuist generate -n")
    try shell("CI_PIPELINE=TRUE TYPE=STATIC bundle exec pod install --repo-update")
} catch {
    fatalError(error.localizedDescription)
}


