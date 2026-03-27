import SwiftUI
#if os(iOS)
import UIKit
#endif

struct WelcomeView: View {
    var onBegin: () -> Void
    @State private var appear = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("Felt")
                    .font(.system(size: 52, weight: .bold, design: .serif))
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)

                Text("How does today feel?")
                    .font(.title3)
                    .foregroundStyle(FeltTheme.subtleText)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 15)
            }

            // Mood gradient preview
            HStack(spacing: 4) {
                ForEach(Mood.allCases) { mood in
                    Circle()
                        .fill(mood.color)
                        .frame(width: 28, height: 28)
                        .scaleEffect(appear ? 1.0 : 0.3)
                        .opacity(appear ? 1 : 0)
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appear)

            Spacer()

            VStack(spacing: 12) {
                Text("One moment each day.\nYour feelings, your story.")
                    .font(.subheadline)
                    .foregroundStyle(FeltTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .opacity(appear ? 1 : 0)

                Button {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                    onBegin()
                } label: {
                    Text("Begin")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(FeltTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .opacity(appear ? 1 : 0)
                .padding(.horizontal, 40)
            }

            Spacer(minLength: 40)
        }
        .background(FeltTheme.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appear = true
            }
        }
    }
}
