import Foundation

@MainActor
final class BrowseViewModel: ObservableObject {
    @Published var countries: [Country] = []
    @Published var languages: [Language] = []
    @Published var tags: [Tag] = []
    @Published var isLoadingCountries = false
    @Published var isLoadingLanguages = false
    @Published var isLoadingTags = false
    @Published var countriesError: AppError?
    @Published var languagesError: AppError?
    @Published var tagsError: AppError?

    private let service: RadioBrowserService

    init(service: RadioBrowserService = .shared) {
        self.service = service
    }

    func loadCountries() async {
        guard !isLoadingCountries else { return }
        isLoadingCountries = true
        countriesError = nil

        do {
            let result = try await service.fetchCountries()
            countries = result.sorted { $0.stationcount > $1.stationcount }
        } catch let appError as AppError {
            countriesError = appError
        } catch {
            countriesError = .networkUnavailable
        }

        isLoadingCountries = false
    }

    func loadLanguages() async {
        guard !isLoadingLanguages else { return }
        isLoadingLanguages = true
        languagesError = nil

        do {
            let result = try await service.fetchLanguages()
            languages = result.sorted { $0.stationcount > $1.stationcount }
        } catch let appError as AppError {
            languagesError = appError
        } catch {
            languagesError = .networkUnavailable
        }

        isLoadingLanguages = false
    }

    func loadTags() async {
        guard !isLoadingTags else { return }
        isLoadingTags = true
        tagsError = nil

        do {
            let result = try await service.fetchTags()
            tags = result.sorted { $0.stationcount > $1.stationcount }
        } catch let appError as AppError {
            tagsError = appError
        } catch {
            tagsError = .networkUnavailable
        }

        isLoadingTags = false
    }
}
