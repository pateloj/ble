//
//  AddEditScheduleView.swift
//  BLE Terminal
//
//  Created by Ashwin Gattani on 08/09/25.
//

import SwiftUI

struct AddEditScheduleView: View {
    @Environment(\.presentationMode) var presentation
    @ObservedObject var store: ScheduleStore
    @ObservedObject var ble: BLEManager
    var existing: WaterSchedule? = nil

    @State private var name: String = ""
    @State private var date: Date = Date()
    @State private var minutes: Int = 0
    @State private var seconds: Int = 30
    @State private var repeatDaily: Bool = true
//    @State private var isEnabled: Bool = true
    @State private var showLimitAlert = false
    @State private var showSaveError = false
    @State private var selectedDays: Set<Weekdays> = []


    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Schedule")) {
                    TextField("Name", text: $name)
                    DatePicker(selection: $date, displayedComponents: [.hourAndMinute]) {
                        Text("Time")
                    }
                    Button("Set to Now") {
                        date = Date()
                    }
                }

                Section(header: Text("Duration")) {
                    HStack {
                        Stepper("Minutes: \(minutes)", value: $minutes, in: 0...59)
                    }
                    HStack {
                        Stepper("Seconds: \(seconds)", value: $seconds, in: 0...59)
                    }
                }

                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Weekdays.allCases) { day in
                                    Button {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    } label: {
                                        Text(day.shortName)
                                            .font(.subheadline)
                                            .frame(width: 44, height: 44)
                                            .background(selectedDays.contains(day) ? Color.accentColor : Color.gray.opacity(0.2))
                                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                            .clipShape(Rectangle())
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
//                    Toggle(isOn: $isEnabled) { Text("Enabled") }
                }

                Section {
                    Button(action: save) {
                        Text(existing == nil ? "Save Schedule" : "Update Schedule")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .navigationBarTitle(existing == nil ? "Create Schedule" : "Edit Schedule", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { presentation.wrappedValue.dismiss() })
            .alert(isPresented: $showLimitAlert) {
                Alert(title: Text("Limit reached"), message: Text("You can create up to 3 schedules."), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showSaveError) {
                Alert(title: Text("All fields are required."), message: Text("Please fill up all the details."), dismissButton: .default(Text("OK")))
            }
            .onAppear(perform: populateIfNeeded)
        }
    }

    func populateIfNeeded() {
        guard let e = existing else { return }
        name = e.name
        (minutes, seconds) = secondsToMinSec(e.durationSeconds)
        date = Date.with(hour: e.hour, minutes: e.minutes)
        selectedDays = e.days
    }

    func save() {
        let totalSeconds = minutes * 60 + seconds
        
        if(selectedDays.count == 0 || name.count == 0 || totalSeconds == 0) {
            showSaveError = true
            return
        }
        
        if((ble.connectedPeripheral) != nil) {
            if existing != nil {
                // delete existing schedule and then add again
                let sortedDays = existing!.days.sorted { $0.rawValue < $1.rawValue }
                for selectedDay in sortedDays {
                    ble.sendData(commands.deleteSchedule(weekday: selectedDay.rawValue, hour: existing!.hour, minute: existing!.minutes, seconds: existing!.durationSeconds))
                }
                store.delete(existing!)
            }
            
            // save new schedule
            let calendarComponents = getCalendarComponents(date: date)
            let sortedDays = selectedDays.sorted { $0.rawValue < $1.rawValue }
            for selectedDay in sortedDays {
                ble.sendData(commands.setSchedule(weekday: selectedDay.rawValue, hour: calendarComponents.hour!, minute: calendarComponents.minute!, seconds: totalSeconds))
            }
            
            // save schedule in local
            let new = WaterSchedule(id: existing?.id ?? UUID(), name: name, hour: calendarComponents.hour!, minutes: calendarComponents.minute!, durationSeconds: totalSeconds, days: selectedDays)
            store.add(new)
            store.saveSchedules(ble.connectedPeripheral!.identifier.uuidString)
        }
        
        presentation.wrappedValue.dismiss()
    }
}
