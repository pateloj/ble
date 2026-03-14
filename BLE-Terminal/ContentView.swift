//
//  ContentView.swift
//  BLE Terminal
//
//  Created by Ashwin Gattani on 07/09/25.
//

import SwiftUI

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var ble = BLEManager()
    @State private var uuidInput: String = ""
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                headerView

                devicesList()
            }
            .navigationTitle("Available Devices")
        }
    }

    // MARK: - Header Section
    private var headerView: some View {
        HStack {
            Circle()
                .fill(ble.isPoweredOn ? .green : .red)
                .frame(width: 12, height: 12)
            Text(ble.isPoweredOn ? "Bluetooth On" : "Bluetooth Off")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if ble.isScanning {
                ProgressView()
                Button("Stop") { ble.stopScan() }
            } else {
                Button("Scan") { ble.startScan(); ble.disconnect() }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Devices List
    @ViewBuilder
    private func devicesList() -> some View {
        List {
            Section() {
                ForEach(ble.devices) { info in
                    let isCurrentBLE = ble.connectedPeripheral?.identifier.uuidString == info.id.uuidString

                    NavigationLink(destination: ScheduleView(ble: ble), isActive: .constant(isCurrentBLE)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(info.name.isEmpty ? "(unknown)" : info.name)
                                    .font(.headline)
                            }
                            Spacer()
                            Button(isCurrentBLE ? "Disconnect" : "Connect") {
                                isCurrentBLE ? ble.disconnect() : ble.connect(info)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

}
