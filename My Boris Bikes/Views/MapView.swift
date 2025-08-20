import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var favoritesService: FavoritesService
    @State private var selectedBikePointForDetail: BikePoint?
    @Binding var selectedBikePointForMap: BikePoint?
    
    init(selectedBikePoint: Binding<BikePoint?> = .constant(nil)) {
        self._selectedBikePointForMap = selectedBikePoint
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $viewModel.position) {
                    ForEach(viewModel.visibleBikePoints, id: \.id) { bikePoint in
                        Annotation(bikePoint.commonName, coordinate: bikePoint.coordinate) {
                            BikePointMapPin(
                                bikePoint: bikePoint,
                                isFavorite: favoritesService.isFavorite(bikePoint.id)
                            ) {
                                selectedBikePointForDetail = bikePoint
                            }
                        }
                    }
                    
                    // User location indicator
                    if let userLocation = locationService.location {
                        Annotation("", coordinate: userLocation.coordinate) {
                            UserLocationIndicator()
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat)) // Optimize map rendering
                .mapControlVisibility(.hidden) // Hide unnecessary controls
                .onMapCameraChange { context in
                    // Update bike points when user scrolls to new location or zooms
                    viewModel.updateMapRegion(context.region)
                }
                .onAppear {
                    // If we have a selected bike point when appearing, center on it before setting up location services
                    if let bikePoint = selectedBikePointForMap {
                        viewModel.centerOnBikePoint(bikePoint)
                        selectedBikePointForMap = nil // Reset after centering
                    }
                    viewModel.setup(locationService: locationService)
                }
                .onChange(of: selectedBikePointForMap) { _, newBikePoint in
                    if let bikePoint = newBikePoint {
                        viewModel.centerOnBikePoint(bikePoint)
                        selectedBikePointForMap = nil // Reset after centering
                    }
                }
                
                VStack {
                    Spacer()
                    
                    // Zoom message centered and at bottom
                    if viewModel.shouldShowZoomMessage {
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass.circle")
                                    .foregroundColor(.orange)
                                Text("Please zoom in to see more docks")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground).opacity(0.95))
                            .cornerRadius(8)
                            .shadow(radius: 3)
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                    
                    HStack {
                        Spacer()
                        
                        VStack {
                            Spacer()
                            
                            // Refresh button with animation when loading
                            Button(action: {
                                viewModel.refreshData()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                    .padding(12)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                                    .animation(viewModel.isLoading ? 
                                             Animation.linear(duration: 1.0).repeatForever(autoreverses: false) : 
                                             .default, value: viewModel.isLoading)
                            }
                            .disabled(viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                            .padding(.bottom, 10)
                            
                            // Center on nearest bike point button
                            Button(action: viewModel.centerOnNearestBikePoint) {
                                // Display a bike icon
                                Image(systemName: "bicycle")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                    .padding(12)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .disabled(locationService.location == nil)
                            .opacity(locationService.location == nil ? 0.5 : 1.0)
                            .padding(.bottom, 10)

                            // Center on user location button
                            Button(action: {
                                viewModel.centerOnUserLocation()
                            }) {
                                Image(systemName: "location.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                    .padding(12)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            }
                            .disabled(locationService.location == nil)
                            .opacity(locationService.location == nil ? 0.5 : 1.0)
                            .padding(.bottom, 0) // Above tab bar and message area
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 50) // Above tab bar
                }
                
                // Last update time label
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if let lastUpdate = viewModel.lastUpdateTime {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("Updated \(formatTime(lastUpdate))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemBackground).opacity(0.7))
                            .cornerRadius(8)
                            .shadow(radius: 1)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20) // Above tab bar and other UI elements
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
            .sheet(item: $selectedBikePointForDetail) { bikePoint in
                BikePointDetailView(
                    bikePoint: bikePoint,
                    isFavorite: favoritesService.isFavorite(bikePoint.id)
                ) { bikePoint in
                    favoritesService.toggleFavorite(bikePoint)
                }
                .presentationDetents([.height(280), .medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct BikePointMapPin: View {
    let bikePoint: BikePoint
    let isFavorite: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Simplified donut chart for better performance
                SimplifiedDonutChart(
                    standardBikes: bikePoint.standardBikes,
                    eBikes: bikePoint.eBikes,
                    emptySpaces: bikePoint.emptyDocks,
                    size: 40 // Smaller for better performance
                )

                if !bikePoint.isAvailable {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.orange)
                        .background(Color.black.opacity(0.0))
                        .clipShape(Circle())
                        .offset(x: -10, y: -10)
                }
                
                else if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.yellow)
                        .background(Color.black.opacity(0.0))
                        .clipShape(Circle())
                        .offset(x: -10, y: -10)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .drawingGroup() // Optimize drawing performance
    }
}

struct BikePointDetailView: View {
    let bikePoint: BikePoint
    let isFavorite: Bool
    let onToggleFavorite: (BikePoint) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var hasAnyBikes: Bool {
        bikePoint.standardBikes > 0 || bikePoint.eBikes > 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    DonutChart(
                        standardBikes: bikePoint.standardBikes,
                        eBikes: bikePoint.eBikes,
                        emptySpaces: bikePoint.emptyDocks,
                        size: 60
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(bikePoint.commonName)
                            .font(.headline)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if !bikePoint.isAvailable {
                            Label {
                                Text(bikePoint.isLocked ? "Locked for maintenance" : "Not available")
                            } icon: {
                                Image(systemName: "exclamationmark.triangle")
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                        } else if !hasAnyBikes {
                            Text("No bikes currently available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if bikePoint.totalDocks > 0 {
                            Text("\(bikePoint.emptyDocks) spaces available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                if hasAnyBikes {
                    DonutChartLegend(
                        standardBikes: bikePoint.standardBikes,
                        eBikes: bikePoint.eBikes,
                        emptySpaces: bikePoint.emptyDocks
                    )
                }
                
                Button {
                    onToggleFavorite(bikePoint)
                } label: {
                    HStack {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                        Text(isFavorite ? "Remove from Favorites" : "Add to Favorites")
                    }
                    .foregroundColor(isFavorite ? .red : .accentColor)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .frame(maxHeight: 280) // Fixed maximum height
        .opacity(bikePoint.isAvailable ? 1.0 : 0.7)
    }
}

#Preview {
    MapView()
        .environmentObject(LocationService.shared)
        .environmentObject(FavoritesService.shared)
}