//
//  ContentView.swift
//  My Boris Bikes
//
//  Created by Mike Wagstaff on 08/08/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationService = LocationService.shared
    @StateObject private var favoritesService = FavoritesService.shared
    @State private var selectedTabIndex = 0
    @State private var selectedBikePointForMap: BikePoint?
    
    private var shouldShowLocationBanner: Bool {
        locationService.authorizationStatus == .denied ||
        locationService.authorizationStatus == .restricted ||
        (locationService.authorizationStatus == .notDetermined && locationService.error != nil) ||
        (locationService.authorizationStatus == .authorizedWhenInUse && locationService.location == nil && locationService.error != nil)
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTabIndex) {
                HomeView(onBikePointSelected: { bikePoint in
                    selectedBikePointForMap = bikePoint
                    selectedTabIndex = 1
                })
                .tabItem {
                    Image(systemName: "star")
                    Text("Favourites")
                }
                .tag(0)
                
                MapView(selectedBikePoint: $selectedBikePointForMap)
                    .tabItem {
                        Image(systemName: "map")
                        Text("Map")
                    }
                    .tag(1)
                
                AboutView()
                    .tabItem {
                        Image(systemName: "info.circle")
                        Text("About")
                    }
                    .tag(2)
            }
            .environmentObject(locationService)
            .environmentObject(favoritesService)
            .onAppear {
                // Debug: Force sync with watch on app launch
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    #if os(iOS)
                    favoritesService.forceSyncWithWatch()
                    #endif
                }
            }
            
            if shouldShowLocationBanner {
                VStack {
                    LocationPermissionBanner(
                        locationService: locationService,
                        onRequestPermission: handleLocationPermissionRequest
                    )
                    Spacer()
                }
            }
        }
        .onAppear {
            locationService.requestLocationPermission()
        }
    }
    
    private func handleLocationPermissionRequest() {
        switch locationService.authorizationStatus {
        case .notDetermined:
            locationService.requestLocationPermission()
        case .denied, .restricted:
            openAppSettings()
        default:
            locationService.startLocationUpdates()
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    ContentView()
}
