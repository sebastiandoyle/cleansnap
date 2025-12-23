import Foundation
import SwiftUI

extension Int64 {
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

extension Date {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension Color {
    static let primaryBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let secondaryPurple = Color(red: 0.686, green: 0.322, blue: 0.871)
    static let successGreen = Color(red: 0.196, green: 0.843, blue: 0.294)
    static let warningOrange = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let dangerRed = Color(red: 1.0, green: 0.231, blue: 0.188)

    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let primaryText = Color(UIColor.label)
    static let secondaryText = Color(UIColor.secondaryLabel)
}

extension Double {
    var percentageString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? "0%"
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shakeAmount: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.default) {
                        shakeAmount = 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        shakeAmount = 0
                    }
                }
            }
    }
}
