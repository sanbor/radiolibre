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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Sort", selection: $viewModel.tagsSortOrder) {
                    ForEach(BrowseSortOrder.allCases, id: \.self) { order in
                        Text(order.label).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
        }
        .task { await viewModel.loadTags() }
    }

    private var sectionedTags: [(letter: String, tags: [Tag])] {
        let grouped = Dictionary(grouping: viewModel.sortedTags) { tag in
            String(tag.name.prefix(1)).uppercased()
        }
        return grouped.sorted { $0.key < $1.key }
            .map { (letter: $0.key, tags: $0.value) }
    }

    private var tagList: some View {
        Group {
            if viewModel.tagsSortOrder == .alphabetical {
                alphabeticalList
            } else {
                flatList
            }
        }
    }

    private var alphabeticalList: some View {
        let sections = sectionedTags
        let letters = sections.map(\.letter)

        return ScrollViewReader { proxy in
            List {
                ForEach(sections, id: \.letter) { section in
                    Section {
                        ForEach(section.tags) { tag in
                            tagRow(tag)
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
            ForEach(viewModel.sortedTags) { tag in
                tagRow(tag)
            }

            Color.clear
                .frame(height: 20)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }

    private func tagRow(_ tag: Tag) -> some View {
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
}
