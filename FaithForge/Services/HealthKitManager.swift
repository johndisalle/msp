// HealthKitManager.swift
// FaithForge
//
// Manages HealthKit permissions and data reads for "Rest in God" quests.

import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitManager {
    private let healthStore = HKHealthStore()

    var isAuthorized: Bool = false
    var lastNightSleepHours: Double = 0
    var todayMindfulMinutes: Double = 0

    /// Whether HealthKit is available on this device.
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    /// Request read access to sleep and mindful minutes.
    func requestAuthorization() async {
        guard isAvailable else { return }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            await MainActor.run { self.isAuthorized = true }
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Data Reads

    /// Fetch last night's sleep duration in hours.
    func fetchSleepData() async {
        guard isAvailable else { return }

        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!

        let predicate = HKQuery.predicateForSamples(
            withStart: yesterday,
            end: now,
            options: .strictEndDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            let asleepSamples = samples.filter { sample in
                sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
            }
            let totalSeconds = asleepSamples.reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            }
            await MainActor.run {
                self.lastNightSleepHours = totalSeconds / 3600.0
            }
        } catch {
            print("Sleep data fetch failed: \(error.localizedDescription)")
        }
    }

    /// Fetch today's mindful minutes.
    func fetchMindfulMinutes() async {
        guard isAvailable else { return }

        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let startOfDay = Calendar.current.startOfDay(for: Date())

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictEndDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: mindfulType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            let totalSeconds = samples.reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            }
            await MainActor.run {
                self.todayMindfulMinutes = totalSeconds / 60.0
            }
        } catch {
            print("Mindful minutes fetch failed: \(error.localizedDescription)")
        }
    }

    /// Check if the user got 7+ hours of sleep (for the "Sleep Well" quest).
    var didSleepWell: Bool {
        lastNightSleepHours >= 7.0
    }
}
