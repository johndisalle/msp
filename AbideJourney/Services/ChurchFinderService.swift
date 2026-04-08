import Foundation
import CoreLocation
import MapKit

// MARK: - Church Model

struct NearbyChurch: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let denomination: String
    let address: String
    let distance: Double // miles
    let coordinate: CLLocationCoordinate2D
    let phoneNumber: String?
    let websiteURL: URL?
    let mapItem: MKMapItem

    static func == (lhs: NearbyChurch, rhs: NearbyChurch) -> Bool {
        lhs.id == rhs.id
    }

    var distanceFormatted: String {
        if distance < 0.1 {
            return "Nearby"
        } else if distance < 10 {
            return String(format: "%.1f mi", distance)
        } else {
            return String(format: "%.0f mi", distance)
        }
    }
}

enum ChurchDenomination: String, CaseIterable {
    case all = "All"
    case nonDenominational = "Non-Denominational"
    case baptist = "Baptist"
    case methodist = "Methodist"
    case catholic = "Catholic"
    case presbyterian = "Presbyterian"
    case lutheran = "Lutheran"
    case pentecostal = "Pentecostal"
    case episcopal = "Episcopal"
    case assembliesOfGod = "Assemblies of God"

    var searchTerms: [String] {
        switch self {
        case .all: return ["church", "Christian church", "worship"]
        case .nonDenominational: return ["non-denominational church", "community church"]
        case .baptist: return ["Baptist church"]
        case .methodist: return ["Methodist church", "United Methodist"]
        case .catholic: return ["Catholic church", "Catholic parish"]
        case .presbyterian: return ["Presbyterian church"]
        case .lutheran: return ["Lutheran church"]
        case .pentecostal: return ["Pentecostal church"]
        case .episcopal: return ["Episcopal church", "Anglican church"]
        case .assembliesOfGod: return ["Assemblies of God church"]
        }
    }

    var icon: String {
        switch self {
        case .all: return "building.columns.fill"
        case .nonDenominational: return "cross.fill"
        case .baptist: return "drop.fill"
        case .methodist: return "flame.fill"
        case .catholic: return "building.columns.fill"
        case .presbyterian: return "book.closed.fill"
        case .lutheran: return "cross.circle.fill"
        case .pentecostal: return "flame.circle.fill"
        case .episcopal: return "shield.fill"
        case .assembliesOfGod: return "wind"
        }
    }
}

// MARK: - Church Finder Service

@Observable
final class ChurchFinderService: NSObject, CLLocationManagerDelegate {
    static let shared = ChurchFinderService()

    var churches: [NearbyChurch] = []
    var isLoading = false
    var locationStatus: LocationStatus = .notDetermined
    var userLocation: CLLocationCoordinate2D?
    var errorMessage: String?

    private let locationManager = CLLocationManager()

    enum LocationStatus {
        case notDetermined
        case denied
        case authorized
        case loading
    }

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        locationStatus = .loading
        errorMessage = nil

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationStatus = .authorized
            locationManager.requestLocation()
        case .denied, .restricted:
            locationStatus = .denied
            errorMessage = "Location access is needed to find churches near you. Please enable it in Settings."
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func searchChurches(denomination: ChurchDenomination = .all, radius: Double = 25) {
        guard let location = userLocation else {
            requestLocation()
            return
        }

        isLoading = true
        errorMessage = nil
        churches = []

        let searchTerms = denomination.searchTerms
        let region = MKCoordinateRegion(
            center: location,
            latitudinalMeters: radius * 1609.34, // miles to meters
            longitudinalMeters: radius * 1609.34
        )

        let group = DispatchGroup()
        var allResults: [NearbyChurch] = []

        for term in searchTerms {
            group.enter()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = term
            request.region = region
            request.resultTypes = .pointOfInterest

            let search = MKLocalSearch(request: request)
            search.start { [weak self] response, error in
                defer { group.leave() }
                guard let self, let response else { return }

                let userCL = CLLocation(latitude: location.latitude, longitude: location.longitude)

                let results = response.mapItems.compactMap { item -> NearbyChurch? in
                    guard let name = item.name else { return nil }

                    let itemLocation = CLLocation(
                        latitude: item.placemark.coordinate.latitude,
                        longitude: item.placemark.coordinate.longitude
                    )
                    let distanceMiles = userCL.distance(from: itemLocation) / 1609.34

                    // Filter out results beyond radius
                    guard distanceMiles <= radius else { return nil }

                    let address = [
                        item.placemark.subThoroughfare,
                        item.placemark.thoroughfare,
                        item.placemark.locality,
                        item.placemark.administrativeArea
                    ].compactMap { $0 }.joined(separator: " ")

                    var websiteURL: URL? = nil
                    if let url = item.url {
                        websiteURL = url
                    }

                    return NearbyChurch(
                        name: name,
                        denomination: self.inferDenomination(from: name),
                        address: address.isEmpty ? "Address unavailable" : address,
                        distance: distanceMiles,
                        coordinate: item.placemark.coordinate,
                        phoneNumber: item.phoneNumber,
                        websiteURL: websiteURL,
                        mapItem: item
                    )
                }

                allResults.append(contentsOf: results)
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }

            // Deduplicate by name and proximity
            var seen = Set<String>()
            var unique: [NearbyChurch] = []
            for church in allResults.sorted(by: { $0.distance < $1.distance }) {
                let key = church.name.lowercased()
                if !seen.contains(key) {
                    seen.insert(key)
                    unique.append(church)
                }
            }

            self.churches = unique
            self.isLoading = false

            if unique.isEmpty {
                self.errorMessage = "No churches found nearby. Try expanding your search radius."
            }
        }
    }

    private func inferDenomination(from name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("baptist") { return "Baptist" }
        if lower.contains("methodist") { return "Methodist" }
        if lower.contains("catholic") || lower.contains("parish") { return "Catholic" }
        if lower.contains("presbyterian") { return "Presbyterian" }
        if lower.contains("lutheran") { return "Lutheran" }
        if lower.contains("pentecostal") { return "Pentecostal" }
        if lower.contains("episcopal") || lower.contains("anglican") { return "Episcopal" }
        if lower.contains("assemblies of god") { return "Assemblies of God" }
        if lower.contains("community") || lower.contains("non-denominational") { return "Non-Denominational" }
        return "Church"
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        locationStatus = .authorized
        searchChurches()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        errorMessage = "Unable to determine your location. Please try again."
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationStatus = .authorized
            manager.requestLocation()
        case .denied, .restricted:
            locationStatus = .denied
            errorMessage = "Location access is needed to find churches near you."
        default:
            break
        }
    }

    // MARK: - Actions

    func openInMaps(_ church: NearbyChurch) {
        church.mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    func call(_ church: NearbyChurch) {
        guard let phone = church.phoneNumber,
              let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") else { return }
        UIApplication.shared.open(url)
    }
}
