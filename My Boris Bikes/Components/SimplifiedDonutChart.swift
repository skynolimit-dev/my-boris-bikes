import SwiftUI

struct SimplifiedDonutChart: View {
    let standardBikes: Int
    let eBikes: Int
    let emptySpaces: Int
    let size: CGFloat
    
    private let strokeWidth: CGFloat = 5
    private var circleSize: CGFloat {
        // Reduce the circle size to account for stroke width
        max(size - strokeWidth, size * 0.8)
    }
    
    private var total: Int {
        standardBikes + eBikes + emptySpaces
    }
    
    private var hasData: Bool {
        total > 0
    }
    
    private var standardPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(standardBikes) / Double(total)
    }
    
    private var eBikePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(eBikes) / Double(total)
    }
    
    var body: some View {
        ZStack {
            if !hasData {
                // Simple gray circle for unavailable/no data
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: circleSize, height: circleSize)
            } else {
                // Background circle stroke (empty spaces) - complete the donut ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: strokeWidth)
                    .frame(width: circleSize, height: circleSize)
                
                // Only show bike sections if there are bikes
                if standardBikes + eBikes > 0 {
                    // E-bikes section (blue)
                    if eBikes > 0 {
                        Circle()
                            .trim(from: 0, to: eBikePercentage + standardPercentage)
                            .stroke(AppConstants.Colors.eBike, lineWidth: strokeWidth)
                            .rotationEffect(.degrees(-90))
                            .frame(width: circleSize, height: circleSize)
                    }
                    
                    // Standard bikes section (red) - drawn on top
                    if standardBikes > 0 {
                        Circle()
                            .trim(from: 0, to: standardPercentage)
                            .stroke(AppConstants.Colors.standardBike, lineWidth: strokeWidth)
                            .rotationEffect(.degrees(-90))
                            .frame(width: circleSize, height: circleSize)
                    }
                    
                    // Center indicator showing total bikes
                    Text("\(standardBikes + eBikes)")
                        .font(.system(size: circleSize * 0.3, weight: .bold))
                        // Use the system foreground color for better contrast
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        SimplifiedDonutChart(standardBikes: 5, eBikes: 3, emptySpaces: 12, size: 24)
        SimplifiedDonutChart(standardBikes: 0, eBikes: 0, emptySpaces: 0, size: 24)
        SimplifiedDonutChart(standardBikes: 2, eBikes: 0, emptySpaces: 8, size: 24)
    }
    .padding()
}