import Foundation
import CoreLocation

struct BikePoint: Codable, Identifiable, Equatable {
    let id: String
    let commonName: String
    let url: String
    let lat: Double
    let lon: Double
    let additionalProperties: [AdditionalProperty]
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    var isInstalled: Bool {
        additionalProperties.first { $0.key == "Installed" }?.value == "true"
    }
    
    var isLocked: Bool {
        additionalProperties.first { $0.key == "Locked" }?.value == "true"
    }
    
    var totalDocks: Int {
        Int(additionalProperties.first { $0.key == "NbDocks" }?.value ?? "0") ?? 0
    }
    
    /// Raw number of empty docks from API
    private var rawEmptyDocks: Int {
        Int(additionalProperties.first { $0.key == "NbEmptyDocks" }?.value ?? "0") ?? 0
    }
    
    var standardBikes: Int {
        Int(additionalProperties.first { $0.key == "NbStandardBikes" }?.value ?? "0") ?? 0
    }
    
    var eBikes: Int {
        Int(additionalProperties.first { $0.key == "NbEBikes" }?.value ?? "0") ?? 0
    }
    
    var totalBikes: Int {
        standardBikes + eBikes
    }
    
    /// Number of broken docks calculated from API data
    /// Formula: nbDocks - (nbBikes + nbSpaces) != 0 indicates broken docks
    var brokenDocks: Int {
        let calculatedBrokenDocks = totalDocks - (totalBikes + rawEmptyDocks)
        let brokenCount = max(0, calculatedBrokenDocks)
        
        if brokenCount > 0 {
        }
        
        return brokenCount
    }
    
    /// Adjusted number of empty docks, accounting for broken docks
    /// This is the number of spaces actually available to users
    var emptyDocks: Int {
        // If there are broken docks, we should not show them as available spaces
        // The raw empty docks should already exclude broken ones, but we verify the calculation
        let expectedTotal = totalBikes + rawEmptyDocks + brokenDocks
        
        if expectedTotal == totalDocks {
            // Data is consistent, return raw empty docks
            return rawEmptyDocks
        } else {
            // Data inconsistency detected, calculate adjusted empty docks
            let adjustedEmpty = totalDocks - totalBikes - brokenDocks
            return max(0, adjustedEmpty)
        }
    }
    
    var isAvailable: Bool {
        isInstalled && !isLocked
    }
    
    /// Indicates whether this dock has any broken docks
    var hasBrokenDocks: Bool {
        brokenDocks > 0
    }
}

struct AdditionalProperty: Codable, Equatable {
    let key: String
    let value: String
}