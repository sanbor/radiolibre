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
        .task { await viewModel.loadCountries() }
    }

    private var filteredCountries: [Country] {
        if searchText.isEmpty {
            return viewModel.countries
        }
        return viewModel.countries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var countryList: some View {
        List(filteredCountries) { country in
            NavigationLink {
                StationListView(filter: .country(country.iso_3166_1), title: country.name)
            } label: {
                HStack {
                    Text(country.iso_3166_1.flagEmoji)
                        .font(.title2)
                    Text(country.name)
                    Spacer()
                    Text("\(country.stationcount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
    }
}
