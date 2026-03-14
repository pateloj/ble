//
//  ScheduleCardView.swift
//  BLE Terminal
//
//  Created by Ashwin Gattani on 08/09/25.
//

import SwiftUI

struct ScheduleCardView: View {
    var schedule: WaterSchedule
//    var onToggle: (WaterSchedule) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(schedule.name)
                    .font(.headline)
                                HStack(spacing: 8) {
                                    let (m, s) = secondsToMinSec(schedule.durationSeconds)
                                    Text("Duration: \(m)m \(s)s")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
//                                    Text("•")
//                                        .foregroundColor(.gray)
//                                    Text(schedule.repeatDaily ? "Daily" : "Once")
//                                        .font(.subheadline)
//                                        .foregroundColor(.gray)
                                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
    }
}
