import SwiftUI

struct TagListView: View {
    @StateObject private var viewModel = BrowseViewModel()

    var body: some View {
        Group {
            if viewModel.isLoadingTags && viewModel.tags.isEmpty {
                LoadingView(message: "Loading tags...")
            } else if let error = viewModel.tagsError, viewModel.tags.isEmpty {
                ErrorView(error: error) {
                    await viewModel.loadTags()
                }
            } else {
                tagList
            }
        }
        .navigationTitle("Tags")
        .task { await viewModel.loadTags() }
    }

    private var tagList: some View {
        List(viewModel.tags) { tag in
            NavigationLink {
                StationListView(filter: .tag(tag.name), title: tag.name.capitalized)
            } label: {
                HStack {
                    Text(tag.name)
                    Spacer()
                    Text("\(tag.stationcount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
    }
}
