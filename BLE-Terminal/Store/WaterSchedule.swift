//
//  WaterSchedule.swift
//  BLE Terminal
//
//  Created by Ashwin Gattani on 08/09/25.
//

import SwiftUI

// MARK: - Model
struct WaterSchedule: Identifiable, Equatable, Encodable, Decodable {
    let id: UUID
    var name: String
    var hour: Int
    var minutes: Int
    var durationSeconds: Int // total seconds
    var days: Set<Weekdays>

    init(id: UUID = UUID(), name: String = "New Schedule", hour: Int = 0, minutes: Int = 0, durationSeconds: Int = 30, days: Set<Weekdays> = []) {
        self.id = id
        self.name = name
        self.hour = hour
        self.minutes = minutes
        self.durationSeconds = durationSeconds
        self.days = days
    }
}

// MARK: - Store
class ScheduleStore: ObservableObject {
    @Published var schedules: [WaterSchedule] = []
    let maxSchedules = 3

    func add(_ schedule: WaterSchedule) {
//        guard schedules.count < maxSchedules else { throw StoreError.limitReached }
        schedules.append(schedule)
    }
    
    func saveSchedules(_ deviceUUID: String) {
        if let encoded = try? JSONEncoder().encode(schedules) {
                    UserDefaults.standard.set(encoded, forKey: deviceUUID)
                }
    }
    
    func loadSchedules(_ deviceUUID: String) {
        if let data = UserDefaults.standard.data(forKey: deviceUUID),
           let decoded = try? JSONDecoder().decode([WaterSchedule].self, from: data) {
            schedules = decoded
        }
    }


    func update(_ schedule: WaterSchedule) {
        if let idx = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[idx] = schedule
        }
    }

    func delete(_ schedule: WaterSchedule) {
        schedules.removeAll { $0.id == schedule.id }
    }
    
    func cleanUp() {
        schedules = []
    }

    enum StoreError: Error, LocalizedError {
        case limitReached
        var errorDescription: String? { "You can create up to 3 schedules." }
    }
}
