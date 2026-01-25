//
//  ContentView.swift
//  typo
//
//  Created by content manager on 23/01/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.cursor")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("TexTab is running")
                .font(.title2.bold())

            Text("Press ⌘ + ⇧ + Space to open")
                .foregroundColor(.secondary)

            Text("Or click the menu bar icon")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .frame(width: 300, height: 200)
        .padding()
    }
}

#Preview {
    ContentView()
}
