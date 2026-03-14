//
//  ScheduleDetailView.swift
//  BLE Terminal
//
//  Created by Ashwin Gattani on 08/09/25.
//

import SwiftUI

struct ScheduleDetailView: View {
    @Environment(\.presentationMode) var presentation
    var schedule: WaterSchedule
    @ObservedObject var store: ScheduleStore
    @ObservedObject var ble: BLEManager
    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    
    private func getDaysView() -> some View {
        // Days loop
        HStack(spacing: 8) {
            ForEach(Weekdays.allCases) { day in
                    Text(day.shortName)
                        .font(.subheadline)
                        .frame(width: 44, height: 44)
                        .background(schedule.days.contains(day) ? Color.accentColor : Color.gray.opacity(0.2))
                        .foregroundColor(schedule.days.contains(day) ? .white : .primary)
                        .clipShape(Rectangle())
            }
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text(schedule.name).font(.largeTitle).bold()
                HStack {
                    Text("Time: \(schedule.hour) : \(schedule.minutes)")
                }
                getDaysView()
                HStack {
                    let (m, s) = secondsToMinSec(schedule.durationSeconds)
                    Text("Duration: \(m)m \(s)s")
                }
                .labelsHidden()
            }
            .padding()

            Spacer()

            HStack(spacing: 16) {
                Button(action: { showEdit = true }) {
                    Text("Edit").frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(action: { showDeleteConfirm = true }) {
                    Text("Delete").frame(maxWidth: .infinity)
                }
                .buttonStyle(DeleteButtonStyle())
            }
            .padding()
        }
        .navigationBarTitle("Schedule", displayMode: .inline)
        .sheet(isPresented: $showEdit) {
            AddEditScheduleView(store: store, ble: ble, existing: schedule)
        }
        .alert(isPresented: $showDeleteConfirm) {
            Alert(title: Text("Delete Schedule"), message: Text("Are you sure you want to delete this schedule?"), primaryButton: .destructive(Text("Delete")) {
                
                // delete schedules from devide
                let sortedDays = schedule.days.sorted { $0.rawValue < $1.rawValue }
                for selectedDay in sortedDays {
                    ble.sendData(commands.deleteSchedule(weekday: selectedDay.rawValue, hour: schedule.hour, minute: schedule.minutes, seconds: schedule.durationSeconds))
                }
                
                // update store
                store.delete(schedule)
                store.saveSchedules(ble.connectedPeripheral!.identifier.uuidString)
                
                presentation.wrappedValue.dismiss()
            }, secondaryButton: .cancel())
        }
    }
}
