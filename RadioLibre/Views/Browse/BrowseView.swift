import SwiftUI

struct BrowseView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    CountryListView()
                } label: {
                    Label("Countries", systemImage: "globe")
                }

                NavigationLink {
                    LanguageListView()
                } label: {
                    Label("Languages", systemImage: "character.bubble")
                }

                NavigationLink {
                    TagListView()
                } label: {
                    Label("Tags", systemImage: "tag")
                }
            }
            .navigationTitle("Browse")
        }
    }
}
