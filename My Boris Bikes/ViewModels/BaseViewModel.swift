import Foundation
import Combine

@MainActor
class BaseViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var cancellables = Set<AnyCancellable>()
    private var errorDelayTask: Task<Void, Never>?
    private var pendingError: String?
    
    func setError(_ error: Error) {
        let errorText = error.localizedDescription
        
        // Cancel any pending error display
        errorDelayTask?.cancel()
        
        // Store the pending error
        pendingError = errorText
        
        // Start 20-second delay timer
        errorDelayTask = Task {
            try? await Task.sleep(nanoseconds: 20_000_000_000) // 20 seconds
            
            // Check if task was cancelled or error was cleared
            if !Task.isCancelled, pendingError == errorText {
                errorMessage = errorText
                pendingError = nil
            }
        }
    }
    
    func clearError() {
        // Cancel pending error display
        errorDelayTask?.cancel()
        pendingError = nil
        errorMessage = nil
    }
    
    func clearErrorOnSuccess() {
        // Clear any existing error when operation succeeds
        // This will also cancel pending errors
        clearError()
    }
}