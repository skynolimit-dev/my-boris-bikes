import SwiftUI

struct DonutChart: View {
    let standardBikes: Int
    let eBikes: Int
    let emptySpaces: Int
    let size: CGFloat
    let strokeWidth: CGFloat
    
    @State private var animationAmount: Double = 0
    
    init(standardBikes: Int, eBikes: Int, emptySpaces: Int, size: CGFloat = 60, strokeWidth: CGFloat = 12) {
        self.standardBikes = standardBikes
        self.eBikes = eBikes
        self.emptySpaces = emptySpaces
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    // Create a unique identifier for this configuration to help SwiftUI track changes
    private var chartId: String {
        "\(standardBikes)-\(eBikes)-\(emptySpaces)"
    }
    
    private var total: Int {
        standardBikes + eBikes + emptySpaces
    }
    
    private var standardBikePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(standardBikes) / Double(total)
    }
    
    private var eBikePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(eBikes) / Double(total)
    }
    
    private var emptySpacePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(emptySpaces) / Double(total)
    }
    
    var body: some View {
        ZStack {
            if total == 0 {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: strokeWidth)
                    .frame(width: size, height: size)
                
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.gray)
                    .font(.system(size: size * 0.3))
            } else {
                // Base circle (empty spaces)
                Circle()
                    .stroke(AppConstants.Colors.emptySpace, lineWidth: strokeWidth)
                    .frame(width: size, height: size)
                
                // E-bike and standard bike arc (combined)
                if eBikePercentage > 0 {
                    Circle()
                        .trim(from: 0, to: (eBikePercentage + standardBikePercentage) * animationAmount)
                        .stroke(AppConstants.Colors.eBike, lineWidth: strokeWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: size, height: size)
                        .animation(.easeInOut(duration: 0.6), value: animationAmount)
                }
                
                // Standard bike arc
                if standardBikePercentage > 0 {
                    Circle()
                        .trim(from: 0, to: standardBikePercentage * animationAmount)
                        .stroke(AppConstants.Colors.standardBike, lineWidth: strokeWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: size, height: size)
                        .animation(.easeInOut(duration: 0.6), value: animationAmount)
                }
                
                // Center text with total bikes
                Text("\(standardBikes + eBikes)")
                    .font(.system(size: size * 0.2, weight: .bold))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: standardBikes + eBikes)
            }
        }
        .id(chartId) // Force SwiftUI to recognize this as a new view when data changes
        .onAppear {
            // Trigger animation when the chart appears
            withAnimation(.easeInOut(duration: 0.8)) {
                animationAmount = 1.0
            }
        }
        .onChange(of: chartId) { _, _ in
            // Reset and re-animate when data changes
            animationAmount = 0
            withAnimation(.easeInOut(duration: 0.6)) {
                animationAmount = 1.0
            }
        }
    }
}

struct DonutChartLegend: View {
    let standardBikes: Int
    let eBikes: Int
    let emptySpaces: Int
    let showLabels: Bool
    
    init(standardBikes: Int, eBikes: Int, emptySpaces: Int, showLabels: Bool = true) {
        self.standardBikes = standardBikes
        self.eBikes = eBikes
        self.emptySpaces = emptySpaces
        self.showLabels = showLabels
    }
    
    // Create a unique identifier to help SwiftUI track changes
    private var legendId: String {
        "\(standardBikes)-\(eBikes)-\(emptySpaces)-\(showLabels)"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            LegendItem(
                color: AppConstants.Colors.standardBike,
                count: standardBikes,
                label: showLabels ? "bikes" : nil
            )
            
            LegendItem(
                color: AppConstants.Colors.eBike,
                count: eBikes,
                label: showLabels ? "e-bikes" : nil
            )
            
            LegendItem(
                color: AppConstants.Colors.emptySpace,
                count: emptySpaces,
                label: showLabels ? "spaces" : nil
            )
        }
        .id(legendId) // Help SwiftUI track changes
    }
}

struct LegendItem: View {
    let color: Color
    let count: Int
    let label: String?
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: count)
            
            if let label = label {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DonutChart(standardBikes: 5, eBikes: 3, emptySpaces: 12)
        
        DonutChartLegend(standardBikes: 5, eBikes: 3, emptySpaces: 12)
        
        DonutChart(standardBikes: 0, eBikes: 0, emptySpaces: 0)
    }
    .padding()
}