import SwiftUI
import CoreLocation

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var favoritesService: FavoritesService
    let onBikePointSelected: ((BikePoint) -> Void)?
    
    init(onBikePointSelected: ((BikePoint) -> Void)? = nil) {
        self.onBikePointSelected = onBikePointSelected
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if favoritesService.favorites.isEmpty {
                        EmptyFavoritesView()
                    } else {
                        FavoritesListView(
                            bikePoints: viewModel.favoriteBikePoints,
                            lastUpdateTime: viewModel.lastUpdateTime,
                            onBikePointSelected: onBikePointSelected
                        )
                    }
                }
                .navigationTitle("Favourites")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        SortMenu(
                            sortMode: favoritesService.sortMode,
                            onSortModeChanged: { mode in
                                favoritesService.updateSortMode(mode)
                            }
                        )
                    }
                }
                .refreshable {
                    await viewModel.refreshData()
                }
                .onAppear {
                    viewModel.setup(
                        favoritesService: favoritesService,
                        locationService: locationService
                    )
                }
                
                // Error banner at the top
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        ErrorBanner(
                            message: errorMessage,
                            onDismiss: {
                                viewModel.clearError()
                            }
                        )
                        Spacer()
                    }
                }
            }
        }
    }
}

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Use the map to find and add bike points to your favorites")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct FavoritesListView: View {
    let bikePoints: [BikePoint]
    let lastUpdateTime: Date?
    let onBikePointSelected: ((BikePoint) -> Void)?
    @EnvironmentObject var favoritesService: FavoritesService
    @EnvironmentObject var locationService: LocationService
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(bikePoints, id: \.id) { bikePoint in
                    FavoriteRowView(
                        bikePoint: bikePoint,
                        distance: locationService.distanceString(to: bikePoint.coordinate),
                        onTap: {
                            onBikePointSelected?(bikePoint)
                        }
                    )
                }
                .onDelete(perform: removeFavorites)
                .onMove(perform: favoritesService.sortMode == .manual ? moveFavorites : nil)
            }
            .listStyle(PlainListStyle())
            
            // Last update time label at the bottom
            if let lastUpdate = lastUpdateTime {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("Updated \(formatTime(lastUpdate))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    Spacer()
                }
                // .background(Color(.systemGroupedBackground))
                .padding(.bottom, 8) // Add padding to keep it above the tab bar
            }
        }
    }
    
    private func removeFavorites(offsets: IndexSet) {
        // Create array of IDs to remove
        let bikePointsToRemove = offsets.map { bikePoints[$0] }
        let idsToRemove = bikePointsToRemove.map { $0.id }
        
        // Remove from favorites service
        for id in idsToRemove {
            favoritesService.removeFavorite(id)
        }
    }
    
    private func moveFavorites(from source: IndexSet, to destination: Int) {
        favoritesService.moveFavorite(from: source, to: destination)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct FavoriteRowView: View {
    let bikePoint: BikePoint
    let distance: String
    let onTap: (() -> Void)?
    @EnvironmentObject var locationService: LocationService
    
    @State private var previousStandardBikes: Int?
    @State private var previousEBikes: Int?
    @State private var previousEmptyDocks: Int?
    @State private var isFlashing = false
    
    private var numericDistance: CLLocationDistance? {
        locationService.distance(to: bikePoint.coordinate)
    }
    
    private var hasDataChanged: Bool {
        guard let prevStandard = previousStandardBikes,
              let prevEBikes = previousEBikes,
              let prevEmpty = previousEmptyDocks else {
            return false
        }
        
        return prevStandard != bikePoint.standardBikes ||
               prevEBikes != bikePoint.eBikes ||
               prevEmpty != bikePoint.emptyDocks
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 16) {
                DonutChart(
                    standardBikes: bikePoint.standardBikes,
                    eBikes: bikePoint.eBikes,
                    emptySpaces: bikePoint.emptyDocks,
                    size: 50
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bikePoint.commonName)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack {
                        DonutChartLegend(
                            standardBikes: bikePoint.standardBikes,
                            eBikes: bikePoint.eBikes,
                            emptySpaces: bikePoint.emptyDocks,
                            showLabels: true
                        )
                        
                        Spacer()
                        
                        DistanceIndicator(
                            distance: numericDistance,
                            distanceString: distance
                        )
                    }
                }
                
                if !bikePoint.isAvailable {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
        .opacity(bikePoint.isAvailable ? 1.0 : 0.6)
        .background(
            Rectangle()
                .fill(Color.blue.opacity(isFlashing ? 0.2 : 0.0))
                .animation(.easeInOut(duration: 0.3), value: isFlashing)
        )
        .onAppear {
            // Initialize previous values on first appearance
            previousStandardBikes = bikePoint.standardBikes
            previousEBikes = bikePoint.eBikes
            previousEmptyDocks = bikePoint.emptyDocks
        }
        .onChange(of: bikePoint.standardBikes) { _, _ in
            checkForChangesAndFlash()
        }
        .onChange(of: bikePoint.eBikes) { _, _ in
            checkForChangesAndFlash()
        }
        .onChange(of: bikePoint.emptyDocks) { _, _ in
            checkForChangesAndFlash()
        }
    }
    
    private func checkForChangesAndFlash() {
        // Only flash if we have previous values and data actually changed
        if hasDataChanged {
            // Trigger flash effect
            withAnimation(.easeInOut(duration: 0.15)) {
                isFlashing = true
            }
            
            // Flash off after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFlashing = false
                }
            }
        }
        
        // Update previous values for next comparison
        previousStandardBikes = bikePoint.standardBikes
        previousEBikes = bikePoint.eBikes
        previousEmptyDocks = bikePoint.emptyDocks
    }
}

struct SortMenu: View {
    let sortMode: SortMode
    let onSortModeChanged: (SortMode) -> Void
    
    var body: some View {
        Menu {
            ForEach(SortMode.allCases, id: \.self) { mode in
                Button {
                    onSortModeChanged(mode)
                } label: {
                    HStack {
                        Text(mode.displayName)
                        if mode == sortMode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(LocationService.shared)
        .environmentObject(FavoritesService.shared)
}