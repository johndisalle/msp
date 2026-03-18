import Foundation
import HealthKit

final class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    private let mindfulType = HKCategoryType(.mindfulSession)

    private init() {}

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        let typesToShare: Set<HKSampleType> = [mindfulType]
        let typesToRead: Set<HKObjectType> = [mindfulType]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }

    var authorizationStatus: HKAuthorizationStatus {
        healthStore.authorizationStatus(for: mindfulType)
    }

    // MARK: - Save Mindfulness Session

    func saveMindfulnessSession(startDate: Date, duration: TimeInterval) async throws {
        guard isAvailable else { return }

        let endDate = startDate.addingTimeInterval(duration)

        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate,
            metadata: [
                HKMetadataKeyWasUserEntered: false,
                "AbideJourneySessionType": "Prayer"
            ]
        )

        try await healthStore.save(sample)
    }

    // MARK: - Query Mindfulness Minutes

    func fetchWeeklyMindfulnessMinutes() async throws -> Int {
        guard isAvailable else { return 0 }

        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startOfWeek, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let totalSeconds = (samples ?? []).reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate)
                }

                continuation.resume(returning: Int(totalSeconds / 60))
            }

            self.healthStore.execute(query)
        }
    }

    // MARK: - Query Today's Sessions

    func fetchTodaysSessions() async throws -> [(start: Date, duration: TimeInterval)] {
        guard isAvailable else { return [] }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let sessions = (samples ?? []).map { sample in
                    (start: sample.startDate, duration: sample.endDate.timeIntervalSince(sample.startDate))
                }

                continuation.resume(returning: sessions)
            }

            self.healthStore.execute(query)
        }
    }
}
