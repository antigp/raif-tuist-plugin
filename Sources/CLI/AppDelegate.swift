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
    let window = FloatWindow()
    let windowDelegate = WindowDelegate()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appMenu = NSMenuItem()
        appMenu.submenu = NSMenu()
        appMenu.submenu?.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        appMenu.submenu?.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        appMenu.submenu?.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        appMenu.submenu?.addItem(NSMenuItem(title: "Select all", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        appMenu.submenu?.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let mainMenu = NSMenu(title: "ROnline generator")
        mainMenu.addItem(appMenu)
        NSApplication.shared.mainMenu = mainMenu
        
        let size = CGSize(width: 700, height: 700)
        window.setContentSize(size)
        window.styleMask = [.closable, .miniaturizable, .resizable, .titled]
        window.delegate = windowDelegate
        window.title = "ROnline generator"
        window.orderedIndex = 0
        window.level = .floating
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

class FloatWindow: NSWindow {
    override var isFloatingPanel: Bool { return true }
}
