import SwiftUI

struct WatchDonutChart: View {
    let standardBikes: Int
    let eBikes: Int
    let emptySpaces: Int
    let size: CGFloat
    
    private let strokeWidth: CGFloat = 6
    
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
            if !hasData {
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: size, height: size)
                
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.gray)
                    .font(.system(size: size * 0.3))
            } else {
                // Background circle (empty spaces)
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: strokeWidth)
                    .frame(width: size, height: size)
                
                // E-bikes section (blue)
                if eBikes > 0 {
                    Circle()
                        .trim(from: 0, to: eBikePercentage + standardPercentage)
                        .stroke(Color.blue, lineWidth: strokeWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: size, height: size)
                }
                
                // Standard bikes section (red)
                if standardBikes > 0 {
                    Circle()
                        .trim(from: 0, to: standardPercentage)
                        .stroke(Color.red, lineWidth: strokeWidth)
                        .rotationEffect(.degrees(-90))
                        .frame(width: size, height: size)
                }
                
                // Center text showing total bikes
                Text("\(standardBikes + eBikes)")
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
    }
}

struct WatchDonutChartLegend: View {
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
                .font(.caption2)
                .fontWeight(.medium)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}