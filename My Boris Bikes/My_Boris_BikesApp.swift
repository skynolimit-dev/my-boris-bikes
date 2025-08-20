//
//  My_Boris_BikesApp.swift
//  My Boris Bikes
//
//  Created by Mike Wagstaff on 08/08/2025.
//

import SwiftUI

@main
struct My_Boris_BikesApp: App {
    init() {
        // Initialize WatchConnectivity
        #if os(iOS)
        FavoritesService.shared.setupWatchConnectivity()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
