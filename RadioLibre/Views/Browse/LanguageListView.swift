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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Sort", selection: $viewModel.languagesSortOrder) {
                    ForEach(BrowseSortOrder.allCases, id: \.self) { order in
                        Text(order.label).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
        }
        .task { await viewModel.loadLanguages() }
    }

    private var sectionedLanguages: [(letter: String, languages: [Language])] {
        let grouped = Dictionary(grouping: viewModel.sortedLanguages) { language in
            String(language.name.capitalized.prefix(1)).uppercased()
        }
        return grouped.sorted { $0.key < $1.key }
            .map { (letter: $0.key, languages: $0.value) }
    }

    private var languageList: some View {
        Group {
            if viewModel.languagesSortOrder == .alphabetical {
                alphabeticalList
            } else {
                flatList
            }
        }
    }

    private var alphabeticalList: some View {
        let sections = sectionedLanguages
        let letters = sections.map(\.letter)

        return ScrollViewReader { proxy in
            List {
                ForEach(sections, id: \.letter) { section in
                    Section {
                        ForEach(section.languages) { language in
                            languageRow(language)
                        }
                    } header: {
                        Text(section.letter)
                    }
                    .id(section.letter)
                }

                Color.clear
                    .frame(height: 20)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .overlay(alignment: .trailing) {
                AlphabetIndexView(letters: letters) { letter in
                    withAnimation {
                        proxy.scrollTo(letter, anchor: .top)
                    }
                }
            }
        }
    }

    private var flatList: some View {
        List {
            ForEach(viewModel.sortedLanguages) { language in
                languageRow(language)
            }

            Color.clear
                .frame(height: 20)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private func languageRow(_ language: Language) -> some View {
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
}
