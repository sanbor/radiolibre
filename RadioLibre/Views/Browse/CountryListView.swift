import SwiftUI

struct CountryListView: View {
    @StateObject private var viewModel = BrowseViewModel()
    @State private var searchText = ""

    var body: some View {
        Group {
            if viewModel.isLoadingCountries && viewModel.countries.isEmpty {
                LoadingView(message: "Loading countries...")
            } else if let error = viewModel.countriesError, viewModel.countries.isEmpty {
                ErrorView(error: error) {
                    await viewModel.loadCountries()
                }
            } else {
                countryList
            }
        }
        .navigationTitle("Countries")
        .searchable(text: $searchText, prompt: "Search countries")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Sort", selection: $viewModel.countrySortOrder) {
                    ForEach(BrowseSortOrder.allCases, id: \.self) { order in
                        Text(order.label).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
        }
        .task { await viewModel.loadCountries() }
    }

    private var filteredCountries: [Country] {
        let sorted = viewModel.sortedCountries
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var sectionedCountries: [(letter: String, countries: [Country])] {
        let grouped = Dictionary(grouping: filteredCountries) { country in
            String(country.displayName.prefix(1)).uppercased()
        }
        return grouped.sorted { $0.key < $1.key }
            .map { (letter: $0.key, countries: $0.value) }
    }

    private var countryList: some View {
        Group {
            if viewModel.countrySortOrder == .alphabetical {
                alphabeticalList
            } else {
                flatList
            }
        }
    }

    private var alphabeticalList: some View {
        let sections = sectionedCountries
        let letters = sections.map(\.letter)

        return ScrollViewReader { proxy in
            List {
                ForEach(sections, id: \.letter) { section in
                    Section {
                        ForEach(section.countries) { country in
                            countryRow(country)
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
            ForEach(filteredCountries) { country in
                countryRow(country)
            }

            Color.clear
                .frame(height: 20)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private func countryRow(_ country: Country) -> some View {
        NavigationLink {
            StationListView(filter: .country(country.iso_3166_1), title: country.displayName)
        } label: {
            HStack {
                Text(getFlag(from: country.iso_3166_1))
                    .font(.title2)
                Text(country.displayName)
                Spacer()
                Text("\(country.stationcount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
