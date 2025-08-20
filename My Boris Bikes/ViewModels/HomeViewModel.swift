import Foundation
import Combine
import CoreLocation

@MainActor
class HomeViewModel: BaseViewModel {
    @Published var favoriteBikePoints: [BikePoint] = []
    @Published var lastUpdateTime: Date?
    
    private var favoritesService: FavoritesService?
    private var locationService: LocationService?
    private var refreshTimer: Timer?
    private var bikePointCache: [String: BikePoint] = [:]
    
    func setup(favoritesService: FavoritesService, locationService: LocationService) {
        self.favoritesService = favoritesService
        self.locationService = locationService
        
        favoritesService.$favorites
            .combineLatest(favoritesService.$sortMode)
            .sink { [weak self] favorites, _ in
                // Immediately update the displayed list to match the new favorites
                // This prevents UI/data inconsistencies during deletions
                self?.updateFavoriteBikePointsFromFavoritesList(favorites)
                Task { await self?.loadFavoriteData() }
            }
            .store(in: &cancellables)
        
        // Listen for recently added bike points to cache them immediately
        favoritesService.$recentlyAddedBikePoint
            .compactMap { $0 }
            .sink { [weak self] bikePoint in
                self?.cacheBikePoint(bikePoint)
            }
            .store(in: &cancellables)
        
        locationService.$location
            .sink { [weak self] _ in
                if favoritesService.sortMode == .distance {
                    self?.sortByDistance()
                }
            }
            .store(in: &cancellables)
        
        startAutoRefresh()
    }
    
    func refreshData() async {
        // Force refresh to ensure we get fresh data during manual refresh
        await loadFavoriteData(forceRefresh: true)
    }
    
    func cacheBikePoint(_ bikePoint: BikePoint) {
        bikePointCache[bikePoint.id] = bikePoint
    }
    
    func cacheBikePoints(_ bikePoints: [BikePoint]) {
        for bikePoint in bikePoints {
            bikePointCache[bikePoint.id] = bikePoint
        }
    }
    
    private func updateFavoriteBikePointsFromFavoritesList(_ favorites: [FavoriteBikePoint]) {
        // Immediately filter the current favoriteBikePoints to match the updated favorites list
        // This prevents UI crashes when items are deleted
        let favoriteIds = Set(favorites.map { $0.id })
        favoriteBikePoints = favoriteBikePoints.filter { favoriteIds.contains($0.id) }
    }
    
    private func loadFavoriteData() async {
        await loadFavoriteData(forceRefresh: false)
    }
    
    private func loadFavoriteData(forceRefresh: Bool = false) async {
        guard let favoritesService = favoritesService else { return }
        
        let favoriteIds = favoritesService.favorites.map { $0.id }
        guard !favoriteIds.isEmpty else {
            favoriteBikePoints = []
            return
        }
        
        // Determine which IDs to fetch
        let idsToFetch: [String]
        if forceRefresh || bikePointCache.isEmpty {
            // Fetch all favorites if forcing refresh or no cache
            idsToFetch = favoriteIds
        } else {
            // Only fetch missing IDs
            idsToFetch = favoriteIds.filter { bikePointCache[$0] == nil }
        }
        
        // Show cached data immediately if available and not forcing refresh
        if !forceRefresh && !bikePointCache.isEmpty {
            let cachedBikePoints = favoriteIds.compactMap { bikePointCache[$0] }
            if !cachedBikePoints.isEmpty {
                favoriteBikePoints = sortBikePoints(cachedBikePoints)
            }
        }
        
        // Fetch fresh data if needed
        if !idsToFetch.isEmpty {
            isLoading = true
            clearError()
            
            TfLAPIService.shared
                .fetchMultipleBikePoints(ids: idsToFetch, cacheBusting: forceRefresh)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.setError(error)
                        }
                    },
                    receiveValue: { [weak self] newBikePoints in
                        // Update cache with new data
                        for bikePoint in newBikePoints {
                            self?.bikePointCache[bikePoint.id] = bikePoint
                        }
                        
                        // Combine cached and new data
                        let allBikePoints = favoriteIds.compactMap { self?.bikePointCache[$0] }
                        self?.favoriteBikePoints = self?.sortBikePoints(allBikePoints) ?? []
                        
                        // Update last refresh time
                        self?.lastUpdateTime = Date()
                        
                        // Clear any existing errors on successful data load
                        self?.clearErrorOnSuccess()
                    }
                )
                .store(in: &cancellables)
        } else if forceRefresh {
            // If forcing refresh but no data to fetch, just update timestamp
            lastUpdateTime = Date()
            clearErrorOnSuccess()
        }
    }
    
    private func sortBikePoints(_ bikePoints: [BikePoint]) -> [BikePoint] {
        guard let favoritesService = favoritesService else { return bikePoints }
        
        switch favoritesService.sortMode {
        case .distance:
            return sortBikePointsByDistance(bikePoints)
        case .alphabetical:
            return bikePoints.sorted { $0.commonName.localizedCaseInsensitiveCompare($1.commonName) == .orderedAscending }
        case .manual:
            let favoriteOrder = Dictionary(uniqueKeysWithValues: favoritesService.favorites.enumerated().map { ($1.id, $0) })
            return bikePoints.sorted { favoriteOrder[$0.id, default: Int.max] < favoriteOrder[$1.id, default: Int.max] }
        }
    }
    
    private func sortBikePointsByDistance(_ bikePoints: [BikePoint]) -> [BikePoint] {
        guard let locationService = locationService,
              let userLocation = locationService.location else { return bikePoints }
        
        return bikePoints.sorted { point1, point2 in
            let distance1 = userLocation.distance(from: CLLocation(latitude: point1.lat, longitude: point1.lon))
            let distance2 = userLocation.distance(from: CLLocation(latitude: point2.lat, longitude: point2.lon))
            return distance1 < distance2
        }
    }
    
    private func sortByDistance() {
        guard let locationService = locationService,
              let userLocation = locationService.location else { return }
        
        let sorted = favoriteBikePoints.sorted { point1, point2 in
            let distance1 = userLocation.distance(from: CLLocation(latitude: point1.lat, longitude: point1.lon))
            let distance2 = userLocation.distance(from: CLLocation(latitude: point2.lat, longitude: point2.lon))
            return distance1 < distance2
        }
        
        favoriteBikePoints = sorted
    }
    
    private func startAutoRefresh() {
        var refreshCount = 0
        refreshTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.App.refreshInterval, repeats: true) { [weak self] _ in
            Task {
                refreshCount += 1
                // Force refresh every 4th automatic refresh (every 2 minutes) to ensure fresh data
                let shouldForceRefresh = refreshCount % 4 == 0
                await self?.loadFavoriteData(forceRefresh: shouldForceRefresh)
            }
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}