import SwiftUI

struct AppConstants {
    struct Colors {
        static let standardBike = Color(red: 236/255, green: 0/255, blue: 0/255)
        static let eBike = Color(red: 12/255, green: 17/255, blue: 177/255)
        static let emptySpace = Color(red: 117/255, green: 117/255, blue: 117/255)
    }
    
    struct API {
        static let baseURL = "https://api.tfl.gov.uk"
        static let bikePointEndpoint = "/BikePoint"
        static let placeEndpoint = "/Place"
    }
    
    struct App {
        static let refreshInterval: TimeInterval = 30
        static let appGroup = "group.dev.skynolimit.myborisbikes"
        static let developerURL = "https://skynolimit.dev"
    }
    
    struct UserDefaults {
        static let favoritesKey = "favorites"
        static let sortModeKey = "sortMode"
        static let locationPermissionKey = "locationPermission"
    }
}