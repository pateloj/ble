//
//  ButtonStyles.swift
//  BLE Terminal
//
//  Created by Ashwin Gattani on 08/09/25.
//

import SwiftUI

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.primaryGreen)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.white)
            .foregroundColor(.primary)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primaryGreen, lineWidth: 1))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct DeleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.white)
            .foregroundColor(.red)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red, lineWidth: 1))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
