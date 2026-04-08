import SwiftUI
import MapKit

struct FindChurchView: View {
    @State private var service = ChurchFinderService.shared
    @State private var selectedDenomination: ChurchDenomination = .all
    @State private var searchRadius: Double = 25
    @State private var showingMap = false
    @State private var selectedChurch: NearbyChurch?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var appeared = false

    var body: some View {
        ZStack {
            if service.locationStatus == .notDetermined || service.locationStatus == .loading && service.churches.isEmpty {
                locationPermissionView
            } else if service.locationStatus == .denied {
                deniedView
            } else {
                mainContent
            }
        }
        .navigationTitle("Find a Church")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation { appeared = true }
            if service.locationStatus == .notDetermined {
                // Wait for user to tap
            } else if service.userLocation != nil && service.churches.isEmpty {
                service.searchChurches(denomination: selectedDenomination, radius: searchRadius)
            }
        }
    }

    // MARK: - Permission View

    private var locationPermissionView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AJTheme.sage.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(appeared ? 1 : 0.5)

                Image(systemName: "location.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundStyle(AJTheme.sage)
                    .scaleEffect(appeared ? 1 : 0.5)
            }
            .animation(.spring(response: 0.6), value: appeared)

            VStack(spacing: 12) {
                Text("Find Your Church Home")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(AJTheme.primaryText)

                Text("Discover churches near you where you can worship, grow, and connect with a faith community.")
                    .font(.subheadline)
                    .foregroundStyle(AJTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                service.requestLocation()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                    Text("Allow Location Access")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AJTheme.sage)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)

            Text("Your location is only used to find nearby churches and is never stored.")
                .font(.caption)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Denied View

    private var deniedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "location.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Location Access Needed")
                .font(.system(.title3, design: .serif, weight: .bold))

            Text("To find churches near you, please enable location access in your device Settings.")
                .font(.subheadline)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(AJTheme.sage)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Toggle: List / Map
            Picker("View", selection: $showingMap) {
                Text("List").tag(false)
                Text("Map").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            // Denomination filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ChurchDenomination.allCases, id: \.self) { denom in
                        Button {
                            selectedDenomination = denom
                            service.searchChurches(denomination: denom, radius: searchRadius)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: denom.icon)
                                    .font(.caption2)
                                Text(denom.rawValue)
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedDenomination == denom ? AJTheme.sage : AJTheme.sage.opacity(0.1))
                            )
                            .foregroundStyle(selectedDenomination == denom ? .white : AJTheme.primaryText)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }

            if service.isLoading {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Searching for churches...")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                }
                Spacer()
            } else if let error = service.errorMessage, service.churches.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "building.columns")
                        .font(.system(size: 40))
                        .foregroundStyle(AJTheme.secondaryText)
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Try Again") {
                        service.searchChurches(denomination: selectedDenomination, radius: searchRadius)
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
            } else if showingMap {
                mapView
            } else {
                listView
            }
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $cameraPosition) {
            if let loc = service.userLocation {
                Annotation("You", coordinate: loc) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Circle()
                            .fill(.blue)
                            .frame(width: 12, height: 12)
                    }
                }
            }

            ForEach(service.churches) { church in
                Annotation(church.name, coordinate: church.coordinate) {
                    Button {
                        selectedChurch = church
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "cross.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AJTheme.sage)
                                .background(Circle().fill(.white).padding(-2))
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .onAppear {
            if let loc = service.userLocation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: loc,
                    span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                ))
            }
        }
        .sheet(item: $selectedChurch) { church in
            churchDetailSheet(church)
                .presentationDetents([.medium])
        }
    }

    // MARK: - List View

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Text("\(service.churches.count) churches found")
                    .font(.caption)
                    .foregroundStyle(AJTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                ForEach(service.churches) { church in
                    ChurchCard(church: church) {
                        selectedChurch = church
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .sheet(item: $selectedChurch) { church in
            churchDetailSheet(church)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Church Detail Sheet

    private func churchDetailSheet(_ church: NearbyChurch) -> some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "cross.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AJTheme.sage)

                Text(church.name)
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(church.denomination)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AJTheme.sage))

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(church.distanceFormatted)
                        .font(.caption)
                }
                .foregroundStyle(AJTheme.secondaryText)
            }

            // Address
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                Text(church.address)
                    .font(.subheadline)
                    .foregroundStyle(AJTheme.primaryText)
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AJTheme.cardBackground)
            )

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    service.openInMaps(church)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "car.fill")
                            .font(.title3)
                        Text("Directions")
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AJTheme.sage)
                    )
                    .foregroundStyle(.white)
                }

                if church.phoneNumber != nil {
                    Button {
                        service.call(church)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "phone.fill")
                                .font(.title3)
                            Text("Call")
                                .font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue)
                        )
                        .foregroundStyle(.white)
                    }
                }

                if let url = church.websiteURL {
                    Link(destination: url) {
                        VStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.title3)
                            Text("Website")
                                .font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AJTheme.gold)
                        )
                        .foregroundStyle(.white)
                    }
                }
            }

            // Share button
            ShareLink(item: "\(church.name)\n\(church.address)\n\nFound on Abide Journey") {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share This Church")
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AJTheme.sage, lineWidth: 1.5)
                )
                .foregroundStyle(AJTheme.sage)
            }
        }
        .padding(20)
    }
}

// MARK: - Church Card

private struct ChurchCard: View {
    let church: NearbyChurch
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AJTheme.sage.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: "cross.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AJTheme.sage)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(church.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(AJTheme.primaryText)
                        .lineLimit(1)

                    Text(church.denomination)
                        .font(.caption)
                        .foregroundStyle(AJTheme.sage)

                    Text(church.address)
                        .font(.caption)
                        .foregroundStyle(AJTheme.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(church.distanceFormatted)
                        .font(.caption.bold())
                        .foregroundStyle(AJTheme.sage)

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AJTheme.cardBackground)
                    .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        FindChurchView()
    }
}
