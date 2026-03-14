//
//  ScheduleView.swift
//  BLE Terminal
//
//  Created by Ashwin Gattani on 08/09/25.
//

import SwiftUI

// MARK: - Schedule View
struct ScheduleView: View {
    @ObservedObject var ble: BLEManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var store = ScheduleStore()
    @State private var showAdd = false
    @State private var showLimitAlert = false
    @State private var showQuickRunSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Schedules
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Schedules")
                            .font(.title2).bold()
                        Spacer()
                        Button(action: {
                            if store.schedules.count >= store.maxSchedules {
                                showLimitAlert = true
                            } else {
                                showAdd = true
                            }
                        }) {
                            Image(systemName: "plus")
                                .padding(10)
                                .background(Color.primaryGreen)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    if store.schedules.isEmpty {
                        Text("No schedules yet. Tap + to add.")
                            .foregroundColor(.gray)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(store.schedules) { sched in
                            NavigationLink(destination: ScheduleDetailView(schedule: sched, store: store, ble: ble)) {
                                ScheduleCardView(schedule: sched)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                
                // Quick Run
                QuickRunCardView(ble: ble)
                
                Button("Calibarate AWS") {
                    ble.sendData(commands.calibarateTime())
                }.padding(.vertical, 10)
                    .padding(.horizontal, 18)
                    .foregroundColor(Color.primaryGreen)
                    .cornerRadius(10)
                
                Spacer()
                
                HStack {
                    Button("Disconnect") {
                        ble.disconnect()
                        dismiss()
                    }.padding(.vertical, 10)
                    .padding(.horizontal, 18)
                    .background(Color.primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationBarTitle("AWS 3.0", displayMode: .inline)
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $showAdd) {
                AddEditScheduleView(store: store, ble: ble)
            }
            .alert(isPresented: $showLimitAlert) {
                Alert(title: Text("Limit reached"), message: Text("You can create up to 3 schedules."), dismissButton: .default(Text("OK")))
            }
        }
        .onAppear {
            store.loadSchedules(ble.connectedPeripheral!.identifier.uuidString)
        }
    }
}
