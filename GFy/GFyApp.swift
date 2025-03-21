//
//  GFyApp.swift
//  GFy
//
//  Created by Pulkith Paruchuri on 3/20/25.
//

import SwiftUI

@main
struct GFyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Although we won’t show this window, we still need a settings scene.
        Settings {
            Text("Settings or main app window")
        }
    }
}
