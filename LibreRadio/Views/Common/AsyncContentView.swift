import SwiftUI

/// Reusable wrapper that handles the loading → error → empty → content state pattern.
/// Eliminates duplicate `Group { if isLoading ... else if error ... }` boilerplate across views.
struct AsyncContentView<Content: View, EmptyContent: View>: View {
    let isLoading: Bool
    let error: AppError?
    let isEmpty: Bool
    let loadingMessage: String
    let onRetry: (() async -> Void)?
    @ViewBuilder let emptyContent: () -> EmptyContent
    @ViewBuilder let content: () -> Content

    init(
        isLoading: Bool,
        error: AppError?,
        isEmpty: Bool,
        loadingMessage: String = "Loading...",
        onRetry: (() async -> Void)? = nil,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLoading = isLoading
        self.error = error
        self.isEmpty = isEmpty
        self.loadingMessage = loadingMessage
        self.onRetry = onRetry
        self.emptyContent = emptyContent
        self.content = content
    }

    var body: some View {
        Group {
            if isLoading && isEmpty {
                LoadingView(message: loadingMessage)
            } else if let error, isEmpty {
                ErrorView(error: error, onRetry: onRetry)
            } else if isEmpty {
                emptyContent()
            } else {
                content()
            }
        }
    }
}

// Convenience init for views without a custom empty state (e.g., HomeView).
extension AsyncContentView where EmptyContent == EmptyView {
    init(
        isLoading: Bool,
        error: AppError?,
        isEmpty: Bool,
        loadingMessage: String = "Loading...",
        onRetry: (() async -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            isLoading: isLoading,
            error: error,
            isEmpty: isEmpty,
            loadingMessage: loadingMessage,
            onRetry: onRetry,
            emptyContent: { EmptyView() },
            content: content
        )
    }
}
