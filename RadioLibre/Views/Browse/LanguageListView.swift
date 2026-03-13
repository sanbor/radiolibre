import SwiftUI

struct LanguageListView: View {
    @StateObject private var viewModel = BrowseViewModel()

    var body: some View {
        Group {
            if viewModel.isLoadingLanguages && viewModel.languages.isEmpty {
                LoadingView(message: "Loading languages...")
            } else if let error = viewModel.languagesError, viewModel.languages.isEmpty {
                ErrorView(error: error) {
                    await viewModel.loadLanguages()
                }
            } else {
                languageList
            }
        }
        .navigationTitle("Languages")
        .task { await viewModel.loadLanguages() }
    }

    private var languageList: some View {
        List(viewModel.languages) { language in
            NavigationLink {
                StationListView(filter: .language(language.name), title: language.name.capitalized)
            } label: {
                HStack {
                    Text(language.name.capitalized)
                    Spacer()
                    Text("\(language.stationcount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
    }
}
