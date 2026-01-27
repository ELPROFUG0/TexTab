//
//  LottieView.swift
//  typo
//
//  SwiftUI wrapper for Lottie animations
//

import SwiftUI
import Lottie

struct LottieView: NSViewRepresentable {
    let name: String
    var loopMode: LottieLoopMode = .loop

    func makeNSView(context: Context) -> some NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.masksToBounds = false

        let animationView = LottieAnimationView(name: name)
        animationView.loopMode = loopMode
        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            animationView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        ])

        animationView.play()

        return containerView
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        // No updates needed
    }
}
