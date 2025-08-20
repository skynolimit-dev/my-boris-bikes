import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // App icon or fallback
                if let appIcon = Bundle.main.appIcon {
                    Image(uiImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                } else {
                    // Fallback to bicycle icon if app icon isn't available
                    Image(systemName: "bicycle")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                }
                
                Text("My Boris Bikes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version \(Bundle.main.appVersionString)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Quickly find available Santander Cycles (a.k.a. \"Boris Bikes\") and free dock spaces across London on your iPad, Phone or Watch.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Developed by")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("Sky No Limit", destination: URL(string: AppConstants.App.developerURL)!)
                        .font(.headline)
                        .foregroundColor(.accentColor)
                }

                Spacer()

                Text("Note: This app is not affiliated with TfL or Santander. To hire a bike, please use the official [Santander Cycles app](https://apps.apple.com/gb/app/santander-cycles/id974792287) or the dock terminal.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("About")
        }
    }
}

#Preview {
    AboutView()
}