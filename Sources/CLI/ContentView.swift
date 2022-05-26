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
    @State var searchString = ""
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
                if #available(macOS 12.0, *) {
                    TextField("Search", text: $searchString)
                    ScrollView {
                        ForEach($model.allPods.filter({ $0.name.wrappedValue.contains(searchString) || searchString.isEmpty } )) { pod in
                            HStack {
                                Toggle("is DevPod", isOn: pod.devPod)
                                    .toggleStyle(.checkbox).frame(width: 80, alignment: .leading)
                                Text(pod.name.wrappedValue).frame(width: 150, alignment: .leading)
                                if pod.devPod.wrappedValue {
                                    Text("Branch:").frame(width: 50, alignment: .leading)
                                    TextField("", text: pod.branch).frame(width: 250, alignment: .leading)
                                    
                                } else {
                                    Text("Version:").frame(width: 50, alignment: .leading)
                                    TextField("", text: pod.version).frame(width: 100, alignment: .leading)
                                }
                                Spacer()
                            }.padding()
                        }
                        
                    }
                } else {
                    ScrollView {
                        ForEach($model.allPods) { pod in
                            HStack {
                                Toggle("is DevPod", isOn: pod.devPod)
                                    .toggleStyle(.checkbox).frame(width: 80, alignment: .leading)
                                Text(pod.name.wrappedValue).frame(width: 150, alignment: .leading)
                                if pod.devPod.wrappedValue {
                                    Text("Branch:").frame(width: 50, alignment: .leading)
                                    TextField("", text: pod.branch).frame(width: 250, alignment: .leading)
                                } else {
                                    Text("Version:").frame(width: 50, alignment: .leading)
                                    TextField("", text: pod.version).frame(width: 100, alignment: .leading)
                                }
                                Spacer()
                            }.padding()
                        }
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
            Text("Enter artifactory:")
            TextField("Login", text: $model.enteredLogin)
            SecureField("Password", text: $model.enteredPassword)
            Button {
                model.saveCredentionals()
            } label: {
                Text("Save")
            }
        }
    }
}

