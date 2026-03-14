//
//  MainView.swift
//  BLE Terminal
//
//  Created by Ashwin Gattani on 19/09/25.
//

// SwiftUI BLE ASCII App
// Features:
// - Scan and list nearby BLE peripherals
// - Connect either by selecting from the scan list or by pasting a known CoreBluetooth UUID (CBPeripheral.identifier)
// - Discover services/characteristics automatically
// - Pick the first writable characteristic to send ASCII (UTF-8) data
// - Subscribe to the first notifiable characteristic to receive ASCII data
// - Simple UI for sending/receiving text and viewing logs on a separate detail screen

import SwiftUI

// MARK: - Main View
struct MainView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Dashboard", systemImage: "house").font(.caption)
                }

            ContentView()
                .tabItem {
                    Label("Schedules", systemImage: "calendar").font(.caption)
                }
            
            ContentView()
                .tabItem {
                    Label("Help", systemImage: "questionmark.circle").font(.caption)
                }
        }
    }
}

#Preview {
    MainView()
}
