import SwiftUI

enum AppError: LocalizedError, Identifiable {
    case saveFailed
    case loadFailed
    case invalidAmount
    case profileNotFound
    case storeKitError(String)

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .saveFailed: return "Unable to save your data. Please try again."
        case .loadFailed: return "Unable to load your data. Pull to refresh."
        case .invalidAmount: return "Please enter a valid dollar amount."
        case .profileNotFound: return "Profile not found. Please restart the app."
        case .storeKitError(let message): return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .saveFailed: return "If this continues, try restarting the app."
        case .loadFailed: return "Check that your device has available storage."
        case .invalidAmount: return "Enter a number greater than zero."
        case .profileNotFound: return "Try signing out and back in from Settings."
        case .storeKitError: return "Check your internet connection and try again."
        }
    }
}

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content
            .alert(
                "Something Went Wrong",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                presenting: error
            ) { _ in
                Button("OK", role: .cancel) { error = nil }
            } message: { error in
                VStack {
                    Text(error.localizedDescription)
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                    }
                }
            }
    }
}

extension View {
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}
