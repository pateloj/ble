//
//  QuickRunCardView.swift
//  BLE Terminal
//
//  Created by Ashwin Gattani on 08/09/25.
//

import SwiftUI

struct QuickRunCardView: View {
    @ObservedObject var ble: BLEManager
    
    @State private var minutes: Int = 0
    @State private var seconds: Int = 10
    @State private var running = false
    
    var body: some View {
        VStack() {
            Text("Quick Run")
                .font(.headline)
            HStack() {
                VStack {
                    HStack {
                        Text("Minutes:")
                        Stepper(value: $minutes, in: 0...59) {
                            Text(String(format: "%02d", minutes))
                                .frame(width: 40)
                        }.disabled(running)
                    }
                    HStack {
                        Text("Seconds:")
                        Stepper(value: $seconds, in: 0...59) {
                            Text(String(format: "%02d", seconds))
                                .frame(width: 40)
                        }.disabled(running)
                    }
                }
                .padding(8)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(8)
                
                Spacer()
                
                Button(action: {
                    // Mock run action
                    if(!running) {
                        
                        let totalSeconds = minutes*60 + seconds
                        
                        if(totalSeconds > 0) {
                            ble.sendData(commands.setTime(seconds: totalSeconds))
                            ble.sendData(commands.run.rawValue)
                            
                            running.toggle()
                            
                            // reset button text
                            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(totalSeconds)) {
                                running.toggle()
                            }
                        }
                        
                    }
                }) {
                    HStack {
                        if running {
                            ProgressView()
                        }
                        Text(running ? "Running" : "Run")
                            .bold()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
                    .background(Color.primaryGreen)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }.disabled(running)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
