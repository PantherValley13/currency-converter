//
//  DesignSystem.swift
//  currency converter
//
//  Design system with consistent spacing, typography, and animations
//

import SwiftUI

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Animation Curves

enum AnimationCurve {
    static let quick = Animation.easeOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let smooth = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let energetic = Animation.spring(response: 0.3, dampingFraction: 0.65)
}

// MARK: - Haptic Feedback

enum Haptics {
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// MARK: - View Extensions

extension View {
    /// Ensures minimum tap target size of 44x44 points (Apple HIG)
    func minTapTarget(size: CGFloat = 44) -> some View {
        self.frame(minWidth: size, minHeight: size)
    }
    
    /// Card style with consistent padding and shadow
    func cardStyle(padding: CGFloat = Spacing.lg) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
    }
    
    /// Pulse animation for attention
    func pulseAnimation(trigger: Bool) -> some View {
        self
            .scaleEffect(trigger ? 1.05 : 1.0)
            .animation(AnimationCurve.bouncy, value: trigger)
    }
    
    /// Shake animation for errors
    func shakeAnimation(trigger: Int) -> some View {
        self.modifier(ShakeEffect(shakes: trigger))
    }
    
    /// Shimmer loading effect
    func shimmer(active: Bool = true) -> some View {
        self.modifier(ShimmerModifier(active: active))
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    
    var animatableData: Int {
        get { shakes }
        set { shakes = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = CGFloat(10 * sin(Double(shakes) * .pi * 2))
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if active {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                        .mask(content)
                        .onAppear {
                            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                phase = 1
                            }
                        }
                    }
                }
            )
    }
}

// MARK: - Number Animation

struct AnimatedNumber: View {
    let value: Double
    let formatter: NumberFormatter
    
    @State private var displayValue: Double = 0
    
    init(value: Double, decimalPlaces: Int = 2) {
        self.value = value
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        self.formatter = formatter
    }
    
    var body: some View {
        Text(formatter.string(from: NSNumber(value: displayValue)) ?? "")
            .contentTransition(.numericText(value: displayValue))
            .animation(AnimationCurve.smooth, value: displayValue)
            .onAppear {
                displayValue = value
            }
            .onChange(of: value) { newValue in
                withAnimation(AnimationCurve.smooth) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Loading Skeleton

struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
            .fill(Color(.tertiarySystemBackground))
            .shimmer(active: true)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .padding(Spacing.xl)
                .background(
                    Circle()
                        .fill(Color(.tertiarySystemBackground))
                )
            
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                }
                .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xxl)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                if let message {
                    Text(message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                }
            }
            .padding(Spacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - Enhanced Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let isDestructive: Bool
    
    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(
                Capsule()
                    .fill(isDestructive ? Color.red : Color.accentColor)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AnimationCurve.quick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    Haptics.impact(.light)
                }
            }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AnimationCurve.quick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed {
                    Haptics.impact(.light)
                }
            }
    }
}

// MARK: - Toast/Banner

struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success, error, info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundStyle(type.color)
            
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Quick Amount Presets

struct AmountPresetButton: View {
    let amount: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.impact(.light)
            action()
        }) {
            Text(amount)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(AnimationCurve.bouncy, value: isSelected)
    }
}

// MARK: - Enhanced Result Card

struct ResultCard: View {
    let amount: Double
    let currencyCode: String
    let currencySymbol: String
    let onCopy: () -> Void
    let onShare: () -> Void
    
    @State private var showCopyConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Result")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: Spacing.sm) {
                    Button(action: {
                        Haptics.notification(.success)
                        onCopy()
                        showCopyConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopyConfirmation = false
                        }
                    }) {
                        Image(systemName: showCopyConfirmation ? "checkmark" : "doc.on.doc")
                            .font(.body.weight(.medium))
                            .foregroundStyle(showCopyConfirmation ? .green : .secondary)
                    }
                    .animation(AnimationCurve.bouncy, value: showCopyConfirmation)
                    
                    Button(action: {
                        Haptics.impact(.light)
                        onShare()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .minTapTarget()
            }
            
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(currencySymbol)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)
                
                AnimatedNumber(value: amount, decimalPlaces: 2)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(currencyCode)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

