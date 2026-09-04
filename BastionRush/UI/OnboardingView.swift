import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void
    @State private var page = 0

    private let pages = [
        OnboardingPage(symbol: "hand.draw.fill", title: "Lead the Line", detail: "Drag anywhere to steer your squad. They advance and fire automatically.", color: AppTheme.cyan),
        OnboardingPage(symbol: "arrow.triangle.branch", title: "Make the Call", detail: "Every gate is a tradeoff: grow the squad now, or multiply its firepower.", color: AppTheme.gold),
        OnboardingPage(symbol: "shield.lefthalf.filled", title: "Break the Bastion", detail: "Keep soldiers alive through each wave, then concentrate fire on the fortress.", color: AppTheme.coral)
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.navy, Color(red: 0.03, green: 0.16, blue: 0.24)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 7) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? pages[page].color : .white.opacity(0.15))
                            .frame(width: index == page ? 30 : 8, height: 8)
                    }
                }
                .padding(.top, 28)
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(pages[index]).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onContinue()
                    }
                } label: {
                    HStack {
                        Text(page == pages.count - 1 ? "Deploy" : "Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline.weight(.heavy))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(pages[page].color, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
                .padding(24)
            }
        }
        .foregroundStyle(.white)
    }

    private func pageView(_ item: OnboardingPage) -> some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                Circle().fill(item.color.opacity(0.12)).frame(width: 230, height: 230)
                Circle().stroke(item.color.opacity(0.35), lineWidth: 2).frame(width: 184, height: 184)
                Image(systemName: item.symbol)
                    .font(.system(size: 80, weight: .black))
                    .foregroundStyle(item.color)
                    .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.35))
            }
            VStack(spacing: 12) {
                Text(item.title).font(.largeTitle.weight(.black))
                Text(item.detail)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)
            }
            Spacer()
        }
    }
}

private struct OnboardingPage {
    let symbol: String
    let title: String
    let detail: String
    let color: Color
}
