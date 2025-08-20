//
//  My_Boris_Bikes_Watch_App_Extension.swift
//  My Boris Bikes Watch App Extension
//
//  Created by Mike Wagstaff on 10/08/2025.
//

// ************ WIDGET CHECKPOINT: Workingish... *******************
// TODO:
// Replace custom dock widgets with 3 "picker" widgets which allow you to pick a custom dock after you tap on them!

import WidgetKit
import SwiftUI
import CoreLocation
import AppIntents
import UIKit



// MARK: - Bundle Extension for App Icon
extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}


// MARK: - Navigation Intents for deep linking
@available(iOS 16.0, watchOS 9.0, *)
struct OpenDockDetailIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Dock Detail"
    static var description = IntentDescription("Opens the detail view for a specific dock")
    
    @Parameter(title: "Dock ID")
    var dockId: String
    
    @Parameter(title: "Dock Name") 
    var dockName: String
    
    init(dockId: String, dockName: String) {
        self.dockId = dockId
        self.dockName = dockName
    }
    
    init() {
        self.dockId = ""
        self.dockName = ""
    }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Data Models
struct BorisBikesEntry: TimelineEntry {
    let date: Date
    let closestStation: WidgetBikePoint?
    let error: String?
    let isStaleData: Bool // Indicates if this is fallback data from a transient outage
    
    init(date: Date, closestStation: WidgetBikePoint?, error: String?, isStaleData: Bool = false) {
        self.date = date
        self.closestStation = closestStation
        self.error = error
        self.isStaleData = isStaleData
    }
}

// MARK: - Data Models (duplicated from SharedModels for widget extension)
struct WidgetBikePoint: Codable {
    let id: String
    let commonName: String
    let standardBikes: Int
    let eBikes: Int
    let emptySpaces: Int
    let distance: Double? // Distance in meters
    
    var totalBikes: Int {
        standardBikes + eBikes
    }
    
    var hasData: Bool {
        standardBikes + eBikes + emptySpaces > 0
    }
}

// Helper struct for decoding favorites
struct FavoriteBikePoint: Codable {
    let id: String
    let commonName: String
    let sortOrder: Int
}

// MARK: - Colors matching app theme
struct WidgetColors {
    static let standardBike = Color(red: 236/255, green: 0/255, blue: 0/255)
    static let eBike = Color(red: 12/255, green: 17/255, blue: 177/255)
    static let emptySpace = Color(red: 117/255, green: 117/255, blue: 117/255)
}

// MARK: - Configuration Intent for Configurable Widget
@available(iOS 16.0, watchOS 9.0, *)
struct ConfigurableDockEntity: AppEntity {
    let id: String
    let name: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Dock"
    static var defaultQuery = ConfigurableDockQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct ConfigurableDockQuery: EntityQuery {
    func entities(for identifiers: [ConfigurableDockEntity.ID]) async throws -> [ConfigurableDockEntity] {
        let favorites = loadFavoritesForConfiguration()
        return favorites.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [ConfigurableDockEntity] {
        let entities = loadFavoritesForConfiguration()
        
        // If no favorites are available, return a placeholder to ensure widget appears in picker
        if entities.isEmpty {
            return [ConfigurableDockEntity(id: "no-favorites", name: "Add favorites in the main app")]
        }
        
        // Return suggested entities
        return entities
    }
    
    func defaultResult() async -> ConfigurableDockEntity? {
        let favorites = loadFavoritesForConfiguration()
        if favorites.isEmpty {
            return ConfigurableDockEntity(id: "no-favorites", name: "Add favorites in the main app")
        }
        return favorites.first
    }
    
    private func loadFavoritesForConfiguration() -> [ConfigurableDockEntity] {
        
        let appGroup = "group.dev.skynolimit.myborisbikes"
        
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            return []
        }
        
        
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        guard let data = userDefaults.data(forKey: "favorites") else {
            return []
        }
        
        
        do {
            let favorites = try JSONDecoder().decode([FavoriteBikePoint].self, from: data)
            
            // Log each favorite
            favorites.forEach { favorite in
            }
            
            // Convert to ConfigurableDockEntity and sort alphabetically by name
            let entities = favorites
                .map { ConfigurableDockEntity(id: $0.id, name: $0.commonName) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
            entities.forEach { entity in
            }
            
            return entities
            
        } catch {
            return []
        }
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct ConfigurableDockIntent: WidgetConfigurationIntent, AppIntent {
    static var title: LocalizedStringResource = "Choose Dock"
    static var description = IntentDescription("Choose which dock to display")
    
    @Parameter(title: "Dock", description: "Select a dock to display")
    var dock: ConfigurableDockEntity?
    
    init(dock: ConfigurableDockEntity? = nil) {
        self.dock = dock
    }
    
    init() {
        self.dock = nil
    }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - App Intent Configuration Refresh Helper
@available(iOS 16.0, watchOS 9.0, *)
struct ConfigurableDockRefreshManager {
    static func invalidateConfigurableWidgetRecommendations() {
        
        // Force reload of all configurable dock widgets to refresh their configuration options
        WidgetCenter.shared.reloadTimelines(ofKind: "MyBorisBikesConfigurableDockCircularComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "MyBorisBikesConfigurableDockRectangularComplication")
        
        // Force refresh of all widget timelines to pick up configuration changes
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
    }
    
    static func startObservingFavoritesChanges() {
        
        // Remove any existing observers first to avoid duplicates
        NotificationCenter.default.removeObserver(self, name: .favoritesDidChange, object: nil)
        
        NotificationCenter.default.addObserver(
            forName: .favoritesDidChange,
            object: nil,
            queue: .main
        ) { notification in
            
            // Immediate refresh
            invalidateConfigurableWidgetRecommendations()
            
            // Also trigger refreshes with delays to ensure data is propagated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                invalidateConfigurableWidgetRecommendations()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                invalidateConfigurableWidgetRecommendations()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                invalidateConfigurableWidgetRecommendations()
            }
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let favoritesDidChange = Notification.Name("favoritesDidChange")
}

// MARK: - Timeline Provider
struct BorisBikesTimelineProvider: TimelineProvider {
    private let appGroup = "group.dev.skynolimit.myborisbikes"
    
    init() {
    }
    
    func placeholder(in context: Context) -> BorisBikesEntry {
        return BorisBikesEntry(
            date: Date(),
            closestStation: WidgetBikePoint(
                id: "placeholder",
                commonName: "PLACEHOLDER",
                standardBikes: 1,
                eBikes: 1,
                emptySpaces: 1,
                distance: nil
            ),
            error: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BorisBikesEntry) -> ()) {
        let entry = loadCurrentData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BorisBikesEntry>) -> ()) {
        var entries: [BorisBikesEntry] = []
        let currentDate = Date()
        
        // Create current entry
        let currentEntry = loadCurrentData()
        entries.append(currentEntry)
        
        // Determine refresh strategy based on data staleness and errors
        let (refreshInterval, policyInterval) = determineRefreshStrategy(for: currentEntry)
        
        // Create entries for next period with appropriate intervals
        let maxEntries = min(20, (5 * 60) / refreshInterval) // Cap at 20 entries or 5 minutes worth
        for i in 1...maxEntries {
            let entryDate = Calendar.current.date(byAdding: .second, value: i * refreshInterval, to: currentDate)!
            let entry = BorisBikesEntry(
                date: entryDate,
                closestStation: currentEntry.closestStation,
                error: currentEntry.error
            )
            entries.append(entry)
        }
        
        // Set timeline policy based on data freshness
        let nextUpdate = Calendar.current.date(byAdding: .second, value: policyInterval, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    /// Gets last known good data for main widget during update locks
    private func getLastKnownGoodDataFromMainWidget() -> WidgetBikePoint? {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return nil }
        
        guard let lastKnownGoodData = userDefaults.data(forKey: "widget_last_known_good_data") else {
            return nil
        }
        
        let lastKnownGoodTimestamp = userDefaults.double(forKey: "widget_last_known_good_timestamp")
        let dataAge = Date().timeIntervalSince1970 - lastKnownGoodTimestamp
        
        // Only use fallback data if it's less than 10 minutes old
        guard dataAge < 600 else {
            return nil
        }
        
        do {
            let fallbackStation = try JSONDecoder().decode(WidgetBikePoint.self, from: lastKnownGoodData)
            return fallbackStation
        } catch {
            return nil
        }
    }
    
    /// Determines refresh strategy based on data freshness and connection status
    private func determineRefreshStrategy(for entry: BorisBikesEntry) -> (entryInterval: Int, policyInterval: Int) {
        // Check data age to determine refresh aggressiveness
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            // No app group access - use aggressive refresh to try to recover
            return (10, 15)
        }
        
        let dataTimestamp = userDefaults.double(forKey: "widget_data_timestamp")
        let dataAge = Date().timeIntervalSince1970 - dataTimestamp
        
        // Determine if we have an error condition
        let hasError = entry.error != nil && entry.error != ""
        let hasStaleData = dataAge > 120 // Data older than 2 minutes
        let hasNoData = entry.closestStation == nil
        
        
        // Check if this is startup scenario to avoid aggressive refreshes
        let isStartup = dataTimestamp == 0
        
        if hasNoData || hasError {
            if isStartup {
                // During startup, use longer intervals to let initial data load complete
                return (120, 180)
            } else {
                // No data or error - moderate refresh to avoid rate limiting
                requestCacheBustedRefresh(reason: "No data or error")
                return (60, 90)
            }
        } else if hasStaleData {
            // Stale data - moderate refresh to avoid overwhelming API
            requestCacheBustedRefresh(reason: "Stale data (age: \(Int(dataAge))s)")
            return (90, 120)
        } else if dataAge > 60 {
            // Somewhat old data - normal refresh
            return (60, 90)
        } else {
            // Fresh data - normal refresh
            return (60, 60)
        }
    }
    
    /// Requests that the main app perform a cache-busted refresh
    private func requestCacheBustedRefresh(reason: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return }
        
        let requestKey = "cache_busted_refresh_request"
        let request: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "reason": reason,
            "source": "widget_timeline"
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: request)
            userDefaults.set(data, forKey: requestKey)
        } catch {
        }
    }
    
    private func loadCurrentData() -> BorisBikesEntry {
        
        // Note: Update locks removed to prevent data drought during refreshes
        
        
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            return BorisBikesEntry(
                date: Date(),
                closestStation: WidgetBikePoint(
                    id: "no-access",
                    commonName: "No App Group Access",
                    standardBikes: 0,
                    eBikes: 0,
                    emptySpaces: 0,
                    distance: nil
                ),
                error: "No app group access"
            )
        }
        
        
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        // Get favorites from UserDefaults
        guard let favoritesData = userDefaults.data(forKey: "favorites") else {
            
            // Check for last known good data before showing error
            if let fallbackStation = getLastKnownGoodDataFromWidget() {
                return BorisBikesEntry(date: Date(), closestStation: fallbackStation, error: nil)
            }
            
            return BorisBikesEntry(date: Date(), closestStation: nil, error: "No favorites data")
        }
        
        
        guard let favorites = try? JSONDecoder().decode([FavoriteBikePoint].self, from: favoritesData) else {
            return BorisBikesEntry(date: Date(), closestStation: nil, error: "Invalid favorites data")
        }
        
        guard !favorites.isEmpty else {
            
            // Check for last known good data before showing error
            if let fallbackStation = getLastKnownGoodDataFromWidget() {
                return BorisBikesEntry(date: Date(), closestStation: fallbackStation, error: nil)
            }
            
            return BorisBikesEntry(date: Date(), closestStation: nil, error: "No favorites found")
        }
        
        
        // Try to get cached bike point data from shared file first
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            let fileURL = containerURL.appendingPathComponent("widget_data.json")
            
            if let fileData = try? Data(contentsOf: fileURL) {
                
                if let cachedStation = try? JSONDecoder().decode(WidgetBikePoint.self, from: fileData) {
                    return BorisBikesEntry(date: Date(), closestStation: cachedStation, error: nil)
                } else {
                }
            }
        }
        
        // Fallback to UserDefaults
        if let cachedData = userDefaults.data(forKey: "widget_closest_station") {
            
            if let cachedStation = try? JSONDecoder().decode(WidgetBikePoint.self, from: cachedData) {
                
                // Check timestamp to see how fresh the data is
                let dataTimestamp = userDefaults.double(forKey: "widget_data_timestamp")
                let age = Date().timeIntervalSince1970 - dataTimestamp
                
                
                return BorisBikesEntry(date: Date(), closestStation: cachedStation, error: nil)
            }
        }
        
        // Before showing error, check for last known good data (fallback for transient network issues)
        if let fallbackStation = getLastKnownGoodDataFromWidget() {
            return BorisBikesEntry(date: Date(), closestStation: fallbackStation, error: nil)
        }
        
        
        // Fallback: use first favorite with placeholder data BUT NO ERROR to avoid exclamation mark
        let firstFavorite = favorites.first!
        
        let widgetStation = WidgetBikePoint(
            id: firstFavorite.id,
            commonName: firstFavorite.commonName,
            standardBikes: 0, // No data available
            eBikes: 0,
            emptySpaces: 0,
            distance: nil
        )
        
        return BorisBikesEntry(date: Date(), closestStation: widgetStation, error: nil)
    }
    
    // Check if data has changed since last update
    private func hasDataChanged() -> Bool {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return false }
        
        let currentTimestamp = userDefaults.double(forKey: "widget_data_timestamp")
        let lastKnownTimestamp = userDefaults.double(forKey: "widget_last_update_timestamp")
        
        return currentTimestamp != lastKnownTimestamp
    }
    
    // Mark that we've processed the latest data
    private func markDataAsProcessed() {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return }
        
        let currentTimestamp = userDefaults.double(forKey: "widget_data_timestamp")
        userDefaults.set(currentTimestamp, forKey: "widget_last_update_timestamp")
    }
    
    // Helper function to get last known good data for fallback during transient network issues
    private func getLastKnownGoodDataFromWidget() -> WidgetBikePoint? {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return nil }
        
        guard let lastKnownGoodData = userDefaults.data(forKey: "widget_last_known_good_data") else {
            return nil
        }
        
        let lastKnownGoodTimestamp = userDefaults.double(forKey: "widget_last_known_good_timestamp")
        let dataAge = Date().timeIntervalSince1970 - lastKnownGoodTimestamp
        
        // Only use fallback data if it's less than 10 minutes old
        guard dataAge < 600 else {
            return nil
        }
        
        do {
            let fallbackStation = try JSONDecoder().decode(WidgetBikePoint.self, from: lastKnownGoodData)
            return fallbackStation
        } catch {
            return nil
        }
    }
    
    /// Gets last known good configurable widget data during update locks
    private func getLastKnownGoodConfigurableData() -> [WidgetBikePoint]? {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return nil }
        
        guard let lastKnownGoodData = userDefaults.data(forKey: "bikepoints_last_known_good") else {
            return nil
        }
        
        let lastKnownGoodTimestamp = userDefaults.double(forKey: "bikepoints_last_known_good_timestamp")
        let dataAge = Date().timeIntervalSince1970 - lastKnownGoodTimestamp
        
        // Only use fallback data if it's less than 10 minutes old
        guard dataAge < 600 else {
            return nil
        }
        
        do {
            let fallbackStations = try JSONDecoder().decode([WidgetBikePoint].self, from: lastKnownGoodData)
            return fallbackStations
        } catch {
            return nil
        }
    }
}

// MARK: - Configurable Timeline Provider
@available(iOS 16.0, watchOS 9.0, *)
struct ConfigurableDockTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = BorisBikesEntry
    typealias Intent = ConfigurableDockIntent

    private let appGroup = "group.dev.skynolimit.myborisbikes"

    init() {
    }

    func placeholder(in context: Context) -> Entry {
        BorisBikesEntry(
            date: Date(),
            closestStation: WidgetBikePoint(
                id: "placeholder",
                commonName: "Select Dock",
                standardBikes: 1,
                eBikes: 1,
                emptySpaces: 1,
                distance: nil
            ),
            error: nil
        )
    }

    func snapshot(for configuration: ConfigurableDockIntent, in context: Context) async -> Entry {
        return loadDataForDock(configuration.dock)
    }

    func timeline(for configuration: ConfigurableDockIntent, in context: Context) async -> Timeline<Entry> {

        var entries: [Entry] = []
        let currentDate = Date()

        // Load current data
        let currentEntry = loadDataForDock(configuration.dock)
        entries.append(currentEntry)

        // Determine refresh strategy based on data staleness
        let (refreshInterval, policyInterval) = determineConfigurableRefreshStrategy(for: currentEntry, dock: configuration.dock)

        // Create entries for next period with appropriate intervals
        let maxEntries = min(20, (5 * 60) / refreshInterval)
        for i in 1...maxEntries {
            if let entryDate = Calendar.current.date(byAdding: .second, value: i * refreshInterval, to: currentDate) {
                entries.append(
                    BorisBikesEntry(
                        date: entryDate,
                        closestStation: currentEntry.closestStation,
                        error: currentEntry.error
                    )
                )
            }
        }

        let nextUpdate = Calendar.current.date(byAdding: .second, value: policyInterval, to: currentDate)!
        return Timeline(entries: entries, policy: .after(nextUpdate))
    }
    
    /// Determines refresh strategy for configurable dock widgets based on data freshness
    private func determineConfigurableRefreshStrategy(for entry: BorisBikesEntry, dock: ConfigurableDockEntity?) -> (entryInterval: Int, policyInterval: Int) {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            return (10, 15)
        }
        
        // Check individual dock timestamp if available
        var dataAge: TimeInterval = Double.greatestFiniteMagnitude
        if let dock = dock {
            let dockTimestampKey = "dock_\(dock.id)_timestamp"
            let dockTimestamp = userDefaults.double(forKey: dockTimestampKey)
            if dockTimestamp > 0 {
                dataAge = Date().timeIntervalSince1970 - dockTimestamp
            }
        }
        
        // Fallback to general widget data timestamp
        if dataAge == Double.greatestFiniteMagnitude {
            let generalTimestamp = userDefaults.double(forKey: "widget_data_timestamp")
            if generalTimestamp > 0 {
                dataAge = Date().timeIntervalSince1970 - generalTimestamp
            } else {
                dataAge = 300 // Assume very stale if no timestamp
            }
        }
        
        let hasError = entry.error != nil && entry.error != ""
        let hasStaleData = dataAge > 120
        let hasNoData = entry.closestStation == nil
        
        
        if hasNoData || hasError {
            requestCacheBustedRefreshForConfigurable(reason: "No data or error", dockName: dock?.name)
            return (30, 45)
        } else if hasStaleData {
            requestCacheBustedRefreshForConfigurable(reason: "Stale data (age: \(Int(dataAge))s)", dockName: dock?.name)
            return (45, 60)
        } else if dataAge > 60 {
            return (30, 45)
        } else {
            return (30, 30)
        }
    }
    
    /// Requests that the main app perform a cache-busted refresh for configurable widgets
    private func requestCacheBustedRefreshForConfigurable(reason: String, dockName: String?) {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return }
        
        let requestKey = "cache_busted_refresh_request"
        let request: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "reason": reason,
            "source": "configurable_widget",
            "dock": dockName ?? "unknown"
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: request)
            userDefaults.set(data, forKey: requestKey)
        } catch {
        }
    }

    func recommendations() -> [AppIntentRecommendation<ConfigurableDockIntent>] {
        
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            return []
        }
        
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        guard let data = userDefaults.data(forKey: "favorites") else {
            return []
        }
        
        
        do {
            let favorites = try JSONDecoder().decode([FavoriteBikePoint].self, from: data)
            
            let recommendations = favorites.map { favorite in
                let entity = ConfigurableDockEntity(id: favorite.id, name: favorite.commonName)
                let intent = ConfigurableDockIntent(dock: entity)
                return AppIntentRecommendation(intent: intent, description: favorite.commonName)
            }
            
            favorites.forEach { favorite in
            }
            
            return recommendations
            
        } catch {
            
            if let rawString = String(data: data, encoding: .utf8) {
            }
            
            return []
        }
    }

    private func loadDataForDock(_ selectedDock: ConfigurableDockEntity?) -> Entry {
        guard let dock = selectedDock else {
            return BorisBikesEntry(
                date: Date(),
                closestStation: WidgetBikePoint(
                    id: "noDock",
                    commonName: "No Dock Selected",
                    standardBikes: 0,
                    eBikes: 0,
                    emptySpaces: 0,
                    distance: nil
                ),
                error: "No dock selected"
            )
        }

        // Handle the case when no favorites are configured
        if dock.id == "no-favorites" {
            return BorisBikesEntry(
                date: Date(),
                closestStation: nil,
                error: "Add favorites in the main app first"
            )
        }

        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            return BorisBikesEntry(
                date: Date(),
                closestStation: nil,
                error: "No app group access"
            )
        }
        
        // Try to get current data first
        var bikePoints: [WidgetBikePoint] = []
        if let data = userDefaults.data(forKey: "bikepoints"),
           let currentBikePoints = try? JSONDecoder().decode([WidgetBikePoint].self, from: data) {
            bikePoints = currentBikePoints
        } else {
            // No current data - check for last known good data
            if let fallbackData = userDefaults.data(forKey: "bikepoints_last_known_good") {
                let fallbackTimestamp = userDefaults.double(forKey: "bikepoints_last_known_good_timestamp")
                let dataAge = Date().timeIntervalSince1970 - fallbackTimestamp
                
                // Only use fallback data if it's less than 10 minutes old
                if dataAge < 600, 
                   let fallbackBikePoints = try? JSONDecoder().decode([WidgetBikePoint].self, from: fallbackData) {
                    bikePoints = fallbackBikePoints
                }
            }
            
            // Still no data available
            if bikePoints.isEmpty {
                return BorisBikesEntry(
                    date: Date(),
                    closestStation: nil,
                    error: "No bike point data available"
                )
            }
        }

        if let station = bikePoints.first(where: { $0.id == dock.id }) {
            return BorisBikesEntry(date: Date(), closestStation: station, error: nil)
        } else {
            return BorisBikesEntry(date: Date(), closestStation: nil, error: "Dock not found")
        }
    }
}

// MARK: - Simple Widget Manager for Extension
@available(iOS 16.0, watchOS 9.0, *)
class SimpleWidgetManager {
    static let shared = SimpleWidgetManager()
    private let appGroup = "group.dev.skynolimit.myborisbikes"
    private let widgetConfigPrefix = "widget_dock_"
    
    private init() {}
    
    func getSelectedDockId(for configurationId: String) -> String? {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            return nil
        }
        
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let widgetKeys = allKeys.filter { $0.hasPrefix(widgetConfigPrefix) }
        
        let key = widgetConfigPrefix + configurationId
        let selectedId = userDefaults.string(forKey: key)
        
        
        return selectedId
    }
}

// MARK: - Custom Dock Timeline Provider
@available(iOS 16.0, watchOS 9.0, *)
struct CustomDockTimelineProvider: TimelineProvider {
    typealias Entry = BorisBikesEntry
    
    let widgetId: String
    private let appGroup = "group.dev.skynolimit.myborisbikes"

    init(widgetId: String) {
        self.widgetId = widgetId
    }

    func placeholder(in context: Context) -> Entry {
        BorisBikesEntry(
            date: Date(),
            closestStation: WidgetBikePoint(
                id: "placeholder",
                commonName: "Custom Dock \(widgetId)",
                standardBikes: 1,
                eBikes: 1,
                emptySpaces: 1,
                distance: nil
            ),
            error: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()) {
        let entry = loadDataForWidget()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {

        var entries: [Entry] = []
        let currentDate = Date()

        // Load current data
        let currentEntry = loadDataForWidget()
        entries.append(currentEntry)

        // Determine refresh strategy based on data staleness
        let (refreshInterval, policyInterval) = determineInteractiveRefreshStrategy(for: currentEntry)

        // Create entries for next period with appropriate intervals
        let maxEntries = min(20, (5 * 60) / refreshInterval)
        for i in 1...maxEntries {
            if let entryDate = Calendar.current.date(byAdding: .second, value: i * refreshInterval, to: currentDate) {
                entries.append(
                    BorisBikesEntry(
                        date: entryDate,
                        closestStation: currentEntry.closestStation,
                        error: currentEntry.error
                    )
                )
            }
        }

        let nextUpdate = Calendar.current.date(byAdding: .second, value: policyInterval, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    /// Determines refresh strategy for interactive dock widgets based on data freshness
    private func determineInteractiveRefreshStrategy(for entry: BorisBikesEntry) -> (entryInterval: Int, policyInterval: Int) {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            // No app group access - be very aggressive
            return (5, 10)
        }
        
        // Check if this is showing placeholder "Custom Dock" data
        let isShowingPlaceholder = entry.closestStation?.commonName.contains("Custom Dock") == true
        
        if isShowingPlaceholder {
            // VERY aggressive refresh for placeholder data to get real data ASAP
            requestCacheBustedRefreshForInteractive(reason: "Showing placeholder Custom Dock data", widgetId: widgetId)
            return (5, 10) // Refresh every 5-10 seconds until we get real data
        }
        
        // Check dock-specific timestamp for this widget
        let dockTimestampKey = "dock_\(widgetId)_timestamp"
        let dockTimestamp = userDefaults.double(forKey: dockTimestampKey)
        
        var dataAge: TimeInterval = 300 // Default to very stale
        if dockTimestamp > 0 {
            dataAge = Date().timeIntervalSince1970 - dockTimestamp
        } else {
            // Fallback to general widget timestamp
            let generalTimestamp = userDefaults.double(forKey: "widget_data_timestamp")
            if generalTimestamp > 0 {
                dataAge = Date().timeIntervalSince1970 - generalTimestamp
            }
        }
        
        let hasError = entry.error != nil && entry.error != ""
        let hasStaleData = dataAge > 60 // Reduced from 120 to 60 seconds
        let hasNoData = entry.closestStation == nil
        
        if hasNoData || hasError {
            requestCacheBustedRefreshForInteractive(reason: "No data or error", widgetId: widgetId)
            return (10, 15) // More aggressive than before
        } else if hasStaleData {
            requestCacheBustedRefreshForInteractive(reason: "Stale data (age: \(Int(dataAge))s)", widgetId: widgetId)
            return (15, 30) // More aggressive than before
        } else if dataAge > 30 {
            return (30, 45) // More aggressive refresh
        } else {
            return (45, 60) // Normal refresh when data is fresh
        }
    }
    
    /// Requests that the main app perform a cache-busted refresh for interactive widgets
    private func requestCacheBustedRefreshForInteractive(reason: String, widgetId: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return }
        
        let requestKey = "cache_busted_refresh_request"
        let request: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "reason": reason,
            "source": "interactive_widget",
            "widget_id": widgetId
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: request)
            userDefaults.set(data, forKey: requestKey)
        } catch {
        }
    }

    private func loadDataForWidget() -> BorisBikesEntry {
        // Note: Update locks removed to prevent data drought during refreshes
        
        // Check if this widget has a configured dock
        let selectedDockId = SimpleWidgetManager.shared.getSelectedDockId(for: widgetId)
        
        guard let dockId = selectedDockId else {
            // Widget not configured yet
            return BorisBikesEntry(
                date: Date(),
                closestStation: WidgetBikePoint(
                    id: "not-configured",
                    commonName: "Custom Dock \(widgetId)",
                    standardBikes: 0,
                    eBikes: 0,
                    emptySpaces: 0,
                    distance: nil
                ),
                error: "Tap to configure"
            )
        }

        // Load bike point data for the configured dock
        guard let userDefaults = UserDefaults(suiteName: appGroup) else {
            return BorisBikesEntry(
                date: Date(),
                closestStation: WidgetBikePoint(
                    id: dockId,
                    commonName: "Custom Dock \(widgetId)",
                    standardBikes: 0,
                    eBikes: 0,
                    emptySpaces: 0,
                    distance: nil
                ),
                error: "No app group access"
            )
        }
        
        // Try to get current data first
        var bikePoints: [WidgetBikePoint] = []
        if let data = userDefaults.data(forKey: "bikepoints"),
           let currentBikePoints = try? JSONDecoder().decode([WidgetBikePoint].self, from: data) {
            bikePoints = currentBikePoints
        } else {
            // No current data - check for last known good data
            if let fallbackData = userDefaults.data(forKey: "bikepoints_last_known_good") {
                let fallbackTimestamp = userDefaults.double(forKey: "bikepoints_last_known_good_timestamp")
                let dataAge = Date().timeIntervalSince1970 - fallbackTimestamp
                
                // Only use fallback data if it's less than 10 minutes old
                if dataAge < 600, 
                   let fallbackBikePoints = try? JSONDecoder().decode([WidgetBikePoint].self, from: fallbackData) {
                    bikePoints = fallbackBikePoints
                }
            }
            
            // Still no data available
            if bikePoints.isEmpty {
                return BorisBikesEntry(
                    date: Date(),
                    closestStation: WidgetBikePoint(
                        id: dockId,
                        commonName: "Custom Dock \(widgetId)",
                        standardBikes: 0,
                        eBikes: 0,
                        emptySpaces: 0,
                        distance: nil
                    ),
                    error: "No data available"
                )
            }
        }

        
        if let station = bikePoints.first(where: { $0.id == dockId }) {
            return BorisBikesEntry(date: Date(), closestStation: station, error: nil)
        } else {
            let availableIds = bikePoints.map { $0.id }
            
            return BorisBikesEntry(
                date: Date(),
                closestStation: WidgetBikePoint(
                    id: dockId,
                    commonName: "Custom Dock \(widgetId)",
                    standardBikes: 0,
                    eBikes: 0,
                    emptySpaces: 0,
                    distance: nil
                ),
                error: "Dock not found"
            )
        }
    }
    
    /// Gets last known good configurable widget data during update locks
    private func getLastKnownGoodConfigurableData() -> [WidgetBikePoint]? {
        guard let userDefaults = UserDefaults(suiteName: appGroup) else { return nil }
        
        guard let lastKnownGoodData = userDefaults.data(forKey: "bikepoints_last_known_good") else {
            return nil
        }
        
        let lastKnownGoodTimestamp = userDefaults.double(forKey: "bikepoints_last_known_good_timestamp")
        let dataAge = Date().timeIntervalSince1970 - lastKnownGoodTimestamp
        
        // Only use fallback data if it's less than 10 minutes old
        guard dataAge < 600 else {
            return nil
        }
        
        do {
            let fallbackStations = try JSONDecoder().decode([WidgetBikePoint].self, from: lastKnownGoodData)
            return fallbackStations
        } catch {
            return nil
        }
    }
}

// MARK: - Custom Dock Widget View
@available(iOS 16.0, watchOS 9.0, *)
struct CustomDockWidgetView: View {
    let entry: BorisBikesEntry
    let widgetId: String

    init(entry: BorisBikesEntry, widgetId: String) {
        self.entry = entry
        self.widgetId = widgetId
    }

    var body: some View {
        Group {
            if let station = entry.closestStation {
                if entry.error == "Tap to configure" {
                    VStack(spacing: 2) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("Dock \(widgetId)")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    .widgetURL(URL(string: "myborisbikes://configure-widget/\(widgetId)"))
                } else {
                    ZStack {
                        WidgetDonutChart(
                            standardBikes: station.standardBikes,
                            eBikes: station.eBikes,
                            emptySpaces: station.emptySpaces,
                            name: station.commonName,
                            size: 40
                        )
                    }
                    .widgetURL(URL(string: "myborisbikes://custom-dock/\(widgetId)/\(station.id)"))
                }
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 25, weight: .medium))
                        .foregroundColor(.red)
                    
                    Text("No data")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .widgetURL(URL(string: "myborisbikes://configure-widget/\(widgetId)"))
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Donut Chart Widget View
struct WidgetDonutChart: View {
    let standardBikes: Int
    let eBikes: Int
    let emptySpaces: Int
    let name: String
    let size: CGFloat
    
    private let strokeWidth: CGFloat = 6
    
    init(standardBikes: Int, eBikes: Int, emptySpaces: Int, name: String, size: CGFloat) {
        self.standardBikes = standardBikes
        self.eBikes = eBikes
        self.emptySpaces = emptySpaces
        self.name = name
        self.size = size
        
    }
    
    private var total: Int {
        standardBikes + eBikes + emptySpaces
    }
    
    private var standardPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(standardBikes) / Double(total)
    }
    
    private var eBikePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(eBikes) / Double(total)
    }
    
    private var hasData: Bool {
        total > 0
    }
    
    var body: some View {
        ZStack {
            // If no data is available, show a "refreshing" indicator
            if !hasData {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .resizable()
                    .scaledToFit()
                    .padding(4)
                    .foregroundColor(.secondary)
            } else {
                // Background circle (empty spaces)
                Circle()
                    .stroke(WidgetColors.emptySpace.opacity(0.4), lineWidth: strokeWidth)
                    .frame(width: size, height: size)
                
                // E-bikes section (blue) - outer layer
                if eBikes > 0 {
                    Circle()
                        .trim(from: 0, to: eBikePercentage + standardPercentage)
                        .stroke(WidgetColors.eBike, lineWidth: strokeWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: size, height: size)
                }
                
                // Standard bikes section (red) - inner layer
                if standardBikes > 0 {
                    Circle()
                        .trim(from: 0, to: standardPercentage)
                        .stroke(WidgetColors.standardBike, lineWidth: strokeWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: size, height: size)
                }
                // Center text showing the first 2 initials of the name
                // Get the first letter of each word in station.commonName (separated either by space or comma)
                let initials = name
                    .split(whereSeparator: { $0 == " " || $0 == "," })
                    .compactMap { $0.first }
                    .map { String($0) }
                    .joined()
                    .prefix(2)

                VStack(spacing: 0) {
                    Text(initials)
                        .font(.system(size: size * 0.5, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            } 
        }
    }
}

// MARK: - Rectangular Widget View
struct BorisBikesRectangularComplicationView: View {
    var entry: BorisBikesTimelineProvider.Entry

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                if let station = entry.closestStation {
                    HStack(spacing: 4) {
                        Text(station.commonName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        WidgetDonutChart(
                            standardBikes: station.standardBikes,
                            eBikes: station.eBikes,
                            emptySpaces: station.emptySpaces,
                            name: station.commonName,
                            size: 30
                        )

                        Spacer()

                        WatchDonutChartLegendRectangularComplication(
                            standardBikes: station.standardBikes,
                            eBikes: station.eBikes,
                            emptySpaces: station.emptySpaces
                        )
                        
                    }
                } else if entry.error != nil {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Data")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            
                            Text("Tap to refresh")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                    .onAppear {
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Loading...")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.6)
                            
                            Text("Getting data")
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .containerBackground(.clear, for: .widget)
    }
}



struct WatchDonutChartLegendRectangularComplication: View {
    let standardBikes: Int
    let eBikes: Int
    let emptySpaces: Int
    
    var body: some View {
        HStack(spacing: 8) {
            WatchLegendItem(color: .red, count: standardBikes, label: "bikes")
            WatchLegendItem(color: .blue, count: eBikes, label: "e-bikes")
            WatchLegendItem(color: .gray.opacity(0.6), count: emptySpaces, label: "spaces")
        }
    }
}

struct WatchLegendItem: View {
    let color: Color
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text("\(count)")
                .font(.system(size: 12))
                .fontWeight(.medium)
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}



struct BorisBikesCircularComplicationView: View {
    var entry: BorisBikesTimelineProvider.Entry

    init(entry: BorisBikesTimelineProvider.Entry) {
        self.entry = entry
    }

    var body: some View {
        Group {
            if let station = entry.closestStation {
                if #available(iOS 16.0, watchOS 9.0, *) {
                    ZStack {
                        WidgetDonutChart(
                            standardBikes: station.standardBikes,
                            eBikes: station.eBikes,
                            emptySpaces: station.emptySpaces,
                            name: station.commonName,
                            size: 40
                        )
                    }
                    .widgetURL(URL(string: "myborisbikes://dock/\(station.id)"))
                } else {
                    ZStack {
                        WidgetDonutChart(
                            standardBikes: station.standardBikes,
                            eBikes: station.eBikes,
                            emptySpaces: station.emptySpaces,
                            name: station.commonName,
                            size: 40
                        )
                    }
                }
            } else if entry.error != nil {
                VStack(spacing: 2) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                    
                    Text("No data")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .onAppear {
                }
            } else {
                // Loading state
                VStack(spacing: 2) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Loading")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .containerBackground(.clear, for: .widget)
        .onAppear {
        }
    }
}

@main
struct MyBorisBikesWidgetBundle: WidgetBundle {
    init() {
        
        // Start observing favorites changes for automatic configuration updates
        if #available(iOS 16.0, watchOS 9.0, *) {
            ConfigurableDockRefreshManager.startObservingFavoritesChanges()
        }
    }
    
    var body: some Widget {
        MyBorisBikesClosestDockCircularComplication()
        MyBorisBikesClosestDockRectangularComplication()
        MyBorisBikesSimpleComplication()
        if #available(iOS 16.0, watchOS 9.0, *) {
            CustomDockWidget1()
            CustomDockWidget2()
            CustomDockWidget3()
            CustomDockWidget4()
            CustomDockWidget5()
            CustomDockWidget6()
        }
    }
}

struct MyBorisBikesClosestDockCircularComplication: Widget {
    let kind: String = "MyBorisBikesClosestDockCircularComplication"
    
    init() {
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BorisBikesTimelineProvider()) { entry in
            BorisBikesCircularComplicationView(entry: entry)
        }
        .configurationDisplayName("Closest Favourite")
        .description("Shows closest favorite dock with bike availability")
        .supportedFamilies([.accessoryCircular])
    }
}

struct MyBorisBikesClosestDockRectangularComplication: Widget {
    let kind: String = "MyBorisBikesClosestDockRectangularComplication"
    
    init() {
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BorisBikesTimelineProvider()) { entry in
            BorisBikesRectangularComplicationView(entry: entry)
                .widgetURL(entry.closestStation != nil ? URL(string: "myborisbikes://dock/\(entry.closestStation!.id)") : nil)
        }
        .configurationDisplayName("Closest Favourite Detail")
        .description("Shows closest favorite dock with detailed bike availability")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Simple Launcher Complication
struct SimpleBorisBikesTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BorisBikesEntry {
        BorisBikesEntry(date: Date(), closestStation: nil, error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (BorisBikesEntry) -> ()) {
        let entry = BorisBikesEntry(date: Date(), closestStation: nil, error: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BorisBikesEntry>) -> ()) {
        let currentDate = Date()
        
        // Simple timeline with just one entry that refreshes every hour
        let entry = BorisBikesEntry(date: currentDate, closestStation: nil, error: nil)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}

struct BorisBikesSimpleComplicationView: View {
    var entry: SimpleBorisBikesTimelineProvider.Entry

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "bicycle")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.red)
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct MyBorisBikesSimpleComplication: Widget {
    let kind: String = "MyBorisBikesSimpleComplication"

    init() {
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleBorisBikesTimelineProvider()) { entry in
            BorisBikesSimpleComplicationView(entry: entry)
        }
        .configurationDisplayName("View Favorites")
        .description("Tap to open My Boris Bikes app")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Custom Dock Widgets (6 widgets)

@available(iOS 16.0, watchOS 9.0, *)
struct CustomDockWidget1: Widget {
    let kind: String = "CustomDockWidget1"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomDockTimelineProvider(widgetId: "1")) { entry in
            CustomDockWidgetView(entry: entry, widgetId: "1")
        }
        .configurationDisplayName("Custom Dock 1")
        .description("Configurable dock widget - tap to set up your preferred dock")
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct CustomDockWidget2: Widget {
    let kind: String = "CustomDockWidget2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomDockTimelineProvider(widgetId: "2")) { entry in
            CustomDockWidgetView(entry: entry, widgetId: "2")
        }
        .configurationDisplayName("Custom Dock 2")
        .description("Configurable dock widget - tap to set up your preferred dock")
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct CustomDockWidget3: Widget {
    let kind: String = "CustomDockWidget3"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomDockTimelineProvider(widgetId: "3")) { entry in
            CustomDockWidgetView(entry: entry, widgetId: "3")
        }
        .configurationDisplayName("Custom Dock 3")
        .description("Configurable dock widget - tap to set up your preferred dock")
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct CustomDockWidget4: Widget {
    let kind: String = "CustomDockWidget4"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomDockTimelineProvider(widgetId: "4")) { entry in
            CustomDockWidgetView(entry: entry, widgetId: "4")
        }
        .configurationDisplayName("Custom Dock 4")
        .description("Configurable dock widget - tap to set up your preferred dock")
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct CustomDockWidget5: Widget {
    let kind: String = "CustomDockWidget5"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomDockTimelineProvider(widgetId: "5")) { entry in
            CustomDockWidgetView(entry: entry, widgetId: "5")
        }
        .configurationDisplayName("Custom Dock 5")
        .description("Configurable dock widget - tap to set up your preferred dock")
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOS 16.0, watchOS 9.0, *)
struct CustomDockWidget6: Widget {
    let kind: String = "CustomDockWidget6"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CustomDockTimelineProvider(widgetId: "6")) { entry in
            CustomDockWidgetView(entry: entry, widgetId: "6")
        }
        .configurationDisplayName("Custom Dock 6")
        .description("Configurable dock widget - tap to set up your preferred dock")
        .supportedFamilies([.accessoryCircular])
    }
}

#Preview(as: .accessoryCircular) {
    MyBorisBikesClosestDockCircularComplication()
} timeline: {
    BorisBikesEntry(
        date: .now,
        closestStation: WidgetBikePoint(
            id: "test",
            commonName: "Test Station",
            standardBikes: 5,
            eBikes: 3,
            emptySpaces: 12,
            distance: 200
        ),
        error: nil
    )
    BorisBikesEntry(
        date: .now,
        closestStation: nil,
        error: "No favorites"
    )
}

#Preview(as: .accessoryRectangular) {
    MyBorisBikesClosestDockRectangularComplication()
} timeline: {
    BorisBikesEntry(
        date: .now,
        closestStation: WidgetBikePoint(
            id: "test",
            commonName: "Hyde Park Corner, Hyde Park",
            standardBikes: 5,
            eBikes: 3,
            emptySpaces: 12,
            distance: 200
        ),
        error: nil
    )
    BorisBikesEntry(
        date: .now,
        closestStation: WidgetBikePoint(
            id: "test2",
            commonName: "Very Long Station Name That Might Wrap",
            standardBikes: 0,
            eBikes: 0,
            emptySpaces: 20,
            distance: 500
        ),
        error: nil
    )
    BorisBikesEntry(
        date: .now,
        closestStation: nil,
        error: "No favorites"
    )
}    
