//
//  IconPickerView.swift
//  typo
//
//  Icon picker modal for selecting SF Symbols
//

import SwiftUI

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Environment(\.colorScheme) var colorScheme
    let selectedIcon: String
    let onSelect: (String) -> Void

    @State private var hoveredIcon: String?

    // Icon list with more categories
    let icons: [String] = [
        // Hands - All gestures
        "hand.raised.fill", "hand.thumbsup.fill", "hand.thumbsdown.fill", "hand.wave.fill", "hands.clap.fill",
        "hand.point.up.fill", "hand.point.up.left.fill", "hand.point.down.fill", "hand.point.left.fill", "hand.point.right.fill",
        "hand.draw.fill", "hand.tap.fill", "hand.point.up.braille.fill", "hands.and.sparkles.fill",
        "hand.raised.fingers.spread.fill", "hand.raised.brakesignal", "hands.sparkles.fill",
        "hand.pinch.fill", "hand.rays", "hand.raised.slash.fill", "hand.raised.circle.fill",
        // Translation & Languages
        "translate", "character.book.closed.fill", "textformat.size", "character.bubble.fill",
        "globe", "globe.badge.chevron.backward", "character", "a.book.closed.fill",
        "character.textbox", "text.word.spacing", "textformat.alt", "abc",
        "captions.bubble.fill", "text.redaction", "character.cursor.ibeam",
        // Code & Development
        "chevron.left.forwardslash.chevron.right", "curlybraces", "curlybraces.square.fill", "terminal.fill",
        "apple.terminal.fill", "command.circle.fill", "option.circle.fill", "control.circle.fill",
        "number.circle.fill", "equal.circle.fill", "plus.forwardslash.minus", "function",
        "fx", "sum", "percent", "xmark.app.fill", "app.badge.checkmark.fill",
        "swift", "tuningfork", "cpu.fill", "memorychip.fill", "server.rack",
        "network", "point.3.connected.trianglepath.dotted", "antenna.radiowaves.left.and.right.circle.fill",
        // Math & Numbers
        "number", "textformat.123", "plusminus.circle.fill", "divide.circle.fill", "multiply.circle.fill",
        "lessthan.circle.fill", "greaterthan.circle.fill", "x.squareroot",
        // Sports & Balls
        "sportscourt.fill", "basketball.fill", "football.fill", "tennis.racket", "tennisball.fill",
        "volleyball.fill", "baseball.fill", "soccerball", "figure.basketball", "figure.soccer",
        "figure.tennis", "figure.golf", "figure.bowling", "figure.badminton", "figure.hockey",
        "figure.skiing.downhill", "figure.snowboarding", "figure.surfing", "figure.pool.swim",
        "cricket.ball.fill", "hockey.puck.fill", "figure.american.football", "figure.rugby",
        // Animals & Nature
        "hare.fill", "tortoise.fill", "dog.fill", "cat.fill", "bird.fill", "fish.fill",
        "ant.fill", "ladybug.fill", "leaf.fill", "leaf.arrow.circlepath", "tree.fill",
        "pawprint.fill", "teddybear.fill", "lizard.fill", "bird.circle.fill",
        "rabbit.fill", "fossil.shell.fill", "carrot.fill", "camera.macro",
        // People & Figures
        "person.fill", "person.2.fill", "person.3.fill", "figure.stand", "figure.walk", "figure.run",
        "figure.wave", "figure.arms.open", "figure.2.arms.open", "figure.dance", "figure.martial.arts",
        "person.crop.circle.fill", "person.badge.plus.fill", "person.badge.clock.fill",
        "figure.climbing", "figure.cooldown", "figure.core.training", "figure.flexibility",
        "figure.highintensity.intervaltraining", "figure.jumprope", "figure.mixed.cardio",
        "figure.mind.and.body", "figure.roll", "figure.sailing", "figure.skating",
        // Faces & Expressions
        "face.smiling.fill", "face.dashed.fill", "eyes", "mustache.fill", "mouth.fill", "nose.fill", "ear.fill",
        "brain", "brain.head.profile", "eye.fill", "eye.slash.fill",
        "eyebrow", "eye.trianglebadge.exclamationmark.fill", "eye.circle.fill",
        // Writing & Text
        "pencil", "pencil.line", "highlighter", "scribble.variable", "signature", "text.cursor",
        "pencil.tip", "pencil.and.outline", "square.and.pencil", "rectangle.and.pencil.and.ellipsis",
        "a.magnify", "textformat.abc", "textformat", "bold.italic.underline", "strikethrough",
        "text.alignleft", "text.aligncenter", "text.alignright", "text.justify",
        // Communication
        "text.bubble", "bubble.left", "quote.bubble", "captions.bubble", "ellipsis.message", "phone.fill",
        "message.fill", "envelope.fill", "paperplane.fill", "megaphone.fill",
        "bubble.left.and.bubble.right.fill", "phone.bubble.fill", "video.fill", "video.bubble.fill",
        // Actions & Magic
        "bolt.fill", "wand.and.stars", "sparkles", "star.fill", "heart.fill", "flame.fill",
        "wand.and.rays", "tornado", "wind", "party.popper.fill", "balloon.fill", "balloon.2.fill",
        "wand.and.stars.inverse", "bolt.heart.fill", "bolt.shield.fill", "bolt.ring.closed",
        // Documents & Lists
        "doc.text.fill", "doc.plaintext.fill", "list.bullet", "checklist", "bookmark.fill", "tag.fill",
        "doc.richtext.fill", "doc.append.fill", "note.text", "list.clipboard.fill",
        "doc.badge.plus", "doc.badge.gearshape.fill", "list.bullet.clipboard.fill", "list.bullet.rectangle.fill",
        // Ideas & Mind
        "lightbulb.fill", "moon.fill", "sun.max.fill", "sparkle", "rays", "burst.fill",
        "lightbulb.max.fill", "lightbulb.min.fill", "brain.fill", "brain.head.profile.fill",
        // Tools & Work
        "gearshape.fill", "wrench.and.screwdriver.fill", "hammer.fill", "paintbrush.fill", "scissors", "waveform",
        "briefcase.fill", "folder.fill", "archivebox.fill", "tray.full.fill", "externaldrive.fill",
        "screwdriver.fill", "wrench.adjustable.fill", "level.fill", "ruler.fill", "paintpalette.fill",
        // Symbols & Alerts
        "checkmark.circle.fill", "xmark.circle.fill", "exclamationmark.triangle.fill", "info.circle.fill", "questionmark.circle.fill", "bell.fill",
        "flag.fill", "location.fill", "pin.fill", "mappin.circle.fill", "scope",
        "seal.fill", "checkmark.seal.fill", "xmark.seal.fill", "exclamationmark.circle.fill",
        // Arrows & Movement
        "arrow.triangle.2.circlepath", "arrow.clockwise", "repeat", "shuffle", "arrow.up.circle.fill", "arrow.down.circle.fill",
        "arrow.left.arrow.right", "arrow.up.arrow.down", "arrow.uturn.backward", "arrow.uturn.forward",
        "arrow.3.trianglepath", "arrow.triangle.branch", "arrow.triangle.merge", "arrow.triangle.swap",
        // Objects & Things
        "cup.and.saucer.fill", "gift.fill", "bag.fill", "cart.fill", "creditcard.fill", "building.2.fill",
        "house.fill", "car.fill", "airplane", "bicycle", "bus.fill", "tram.fill",
        "trophy.fill", "medal.fill", "crown.fill", "rosette", "graduationcap.fill",
        "key.fill", "lock.fill", "lock.open.fill", "safe.fill", "wallet.pass.fill",
        // Media & Entertainment
        "play.circle.fill", "pause.circle.fill", "music.note", "mic.fill", "camera.fill", "photo.fill",
        "film.fill", "tv.fill", "gamecontroller.fill", "headphones", "theatermasks.fill",
        "guitars.fill", "pianokeys", "music.mic.circle.fill", "hifispeaker.fill", "radio.fill",
        // Food & Drinks
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "mug.fill", "birthday.cake.fill",
        "takeoutbag.and.cup.and.straw.fill", "popcorn.fill", "carrot.fill", "waterbottle.fill",
        // Nature & Weather
        "cloud.fill", "cloud.rain.fill", "cloud.bolt.fill", "snowflake", "drop.fill", "thermometer.sun.fill",
        "mountain.2.fill", "globe.americas.fill", "globe.europe.africa.fill",
        "sunrise.fill", "sunset.fill", "moon.stars.fill", "rainbow", "humidity.fill",
        // Tech & Devices
        "desktopcomputer", "laptopcomputer", "iphone", "keyboard.fill", "printer.fill", "display",
        "applewatch", "homepod.fill", "appletv.fill", "airpods.gen3",
        "visionpro", "macbook", "ipad", "computermouse.fill", "magicmouse.fill",
        // Health & Fitness
        "heart.circle.fill", "cross.fill", "pills.fill", "bandage.fill", "stethoscope", "figure.yoga",
        "figure.strengthtraining.traditional", "figure.step.training", "dumbbell.fill",
        "lungs.fill", "eye.square.fill", "waveform.path.ecg.rectangle.fill", "medical.thermometer.fill",
        // Shapes
        "circle.fill", "square.fill", "triangle.fill", "diamond.fill", "pentagon.fill", "hexagon.fill",
        "octagon.fill", "seal.fill", "shield.fill", "rhombus.fill", "oval.fill", "capsule.fill",
        // Time & Date
        "clock.fill", "timer", "stopwatch.fill", "alarm.fill", "calendar", "calendar.badge.clock",
        "hourglass", "clock.arrow.circlepath", "calendar.badge.plus"
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(44), spacing: 6), count: 6), spacing: 6) {
                    ForEach(icons, id: \.self) { icon in
                        IconButton(
                            icon: icon,
                            isSelected: selectedIcon == icon,
                            isHovered: hoveredIcon == icon,
                            colorScheme: colorScheme
                        )
                        .onTapGesture {
                            onSelect(icon)
                        }
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredIcon = hovering ? icon : nil
                            }
                        }
                        .help(icon)
                    }
                }
                .padding(12)
                .padding(.bottom, 20)
            }

            // Fade gradient at bottom to indicate more content
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(NSColor.windowBackgroundColor).opacity(0),
                    Color(NSColor.windowBackgroundColor)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)
            .allowsHitTesting(false)
        }
        .frame(width: 320, height: 280)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let isHovered: Bool
    let colorScheme: ColorScheme

    var backgroundColor: Color {
        if isSelected {
            return Color.gray.opacity(0.3)
        } else if isHovered {
            return colorScheme == .light
                ? Color(white: 0.9)
                : Color(white: 0.25)
        }
        return Color.clear
    }

    var iconColor: Color {
        return Color.gray
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .frame(width: 44, height: 44)

            Image(systemName: icon)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(iconColor)
                .scaleEffect(isHovered && !isSelected ? 1.15 : 1.0)
        }
        .frame(width: 44, height: 44)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    IconPickerView(selectedIcon: "star.fill") { icon in
        print("Selected: \(icon)")
    }
    .padding()
}
