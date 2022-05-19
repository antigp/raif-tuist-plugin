//
//  File.swift
//  
//
//  Created by ANTROPOV Evgeny on 19.05.2022.
//

import Foundation
import AppKit
import SwiftUI
import CoreGraphics

@available(macOS 10.15, *)
class AppDelegate: NSObject, NSApplicationDelegate {
    let window = NSWindow()
    let windowDelegate = WindowDelegate()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu()
        appMenu.submenu?.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let mainMenu = NSMenu(title: "ROnline generator")
        mainMenu.addItem(appMenu)
        NSApplication.shared.mainMenu = mainMenu
        
        let size = CGSize(width: 400, height: 500)
        window.setContentSize(size)
        window.styleMask = [.closable, .miniaturizable, .resizable, .titled]
        window.delegate = windowDelegate
        window.title = "ROnline generator"

        let view = NSHostingView(rootView: ContentView())
        view.frame = CGRect(origin: .zero, size: size)
        view.autoresizingMask = [.height, .width]
        window.contentView!.addSubview(view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {[window] in
            window.center()
            window.makeKeyAndOrderFront(window)
            
            NSApp.mainWindow?.makeKeyAndOrderFront(self)
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}
