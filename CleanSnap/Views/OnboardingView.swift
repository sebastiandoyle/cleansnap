import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @EnvironmentObject var storeManager: StoreManager
    @State private var currentPage = 0
    @State private var showingPaywall = false

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sparkles",
            title: "Free Up Space",
            description: "CleanSnap finds duplicate photos, similar images, and large files taking up space on your device.",
            color: .blue
        ),
        OnboardingPage(
            icon: "doc.on.doc.fill",
            title: "Find Duplicates",
            description: "Our smart algorithm detects identical and similar photos so you can keep only the best ones.",
            color: .purple
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Secret Vault",
            description: "Hide your private photos behind a secure PIN. Only you can access them.",
            color: .orange
        ),
        OnboardingPage(
            icon: "bolt.fill",
            title: "One-Tap Cleanup",
            description: "Review and delete unwanted photos with a single tap. It's that easy!",
            color: .green
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 20) {
                pageIndicator

                actionButton
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        VStack(spacing: 12) {
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    showingPaywall = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if currentPage == pages.count - 1 {
                Button {
                    hasSeenOnboarding = true
                } label: {
                    Text("Continue with Limited Access")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 180, height: 180)

                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(page.color)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
        .environmentObject(StoreManager())
}
