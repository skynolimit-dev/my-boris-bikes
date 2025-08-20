import Foundation

struct FavoriteBikePoint: Codable, Identifiable {
    let id: String
    let name: String
    var sortOrder: Int
    
    init(bikePoint: BikePoint, sortOrder: Int = 0) {
        self.id = bikePoint.id
        self.name = bikePoint.commonName
        self.sortOrder = sortOrder
    }
}

enum SortMode: String, CaseIterable {
    case distance = "distance"
    case alphabetical = "alphabetical" 
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .distance: return "Distance"
        case .alphabetical: return "Alphabetical"
        case .manual: return "Manual"
        }
    }
}