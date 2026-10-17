import SwiftUI

struct CalmCentreView: View {

    @Environment(CalmCentreStore.self) private var store

    @State private var showBraindump = false
    @State private var showBreathe = false
    @State private var showJPMR = false
    @State private var showASMR = false
    @State private var showDeepFocus = false
    @State private var currentTipIndex: Int = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Button { showBraindump = true } label: { braindumpCard }
                        .buttonStyle(.plain)

                    relaxationToolsSection
                    dailyTipRow
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AppTheme.appGradient.ignoresSafeArea())
            .navigationTitle("Calm Centre")
            .navigationDestination(isPresented: $showBraindump) {
                BraindumpHomeView()
                    .hideTabBar()
            }
            .navigationDestination(isPresented: $showBreathe) {
                BreatheSessionView()
                    .hideTabBar()
            }
            .navigationDestination(isPresented: $showJPMR) {
                JPMRSessionView()
                    .hideTabBar()
            }
            .navigationDestination(isPresented: $showASMR) {
                SensorySootheView()
                    .hideTabBar()
            }
            .navigationDestination(isPresented: $showDeepFocus) {
                DeepFocusBrowseView()
                    .hideTabBar()
            }
        }
        .toolbarVisibility(isDetailActive ? .hidden : .visible, for: .tabBar)
        .background(TabBarVisibilityHandler(isHidden: isDetailActive))
        .onChange(of: isDetailActive) { _, newValue in
            store.isTabBarHidden = newValue
        }
        .onAppear {
            store.isTabBarHidden = isDetailActive
        }
    }

    private var isDetailActive: Bool {
        showBraindump || showBreathe || showJPMR || showASMR || showDeepFocus
    }

    // MARK: - Subviews

    private var braindumpCard: some View {
        Image("BRAINDUMPCARD")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Braindump")
                        .font(.system(.title2, design: .default, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("Get the noise out\nof your head.")
                        .font(.system(.caption2, design: .default, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    Spacer().frame(height: 2)
                    
                    HStack(spacing: 4) {
                        Text("Start Dumping")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                    }
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .clipShape(Capsule())
                }
                .padding(.leading, 20)
                .padding(.trailing, 160) // Increase right padding to give image more breathing room
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var relaxationToolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Relaxation Tools")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, spacing: 16) {
                Button { showBreathe = true } label: {
                    VStack(spacing: 0) {
                        Image("breathe")
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(1.15)
                            .offset(x: -15, y: 12)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 90, maxHeight: 90)
                            .clipped()
                        
                        VStack(alignment: .center) {
                            Text("4-7-8 Breathing Technique")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(height: 50)
                        .background(Color(.secondarySystemGroupedBackground))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Button { showJPMR = true } label: {
                    VStack(spacing: 0) {
                        Image("JPMR")
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(1.15)
                            .offset(y: 12)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 90, maxHeight: 90)
                            .clipped()
                        
                        VStack(alignment: .center) {
                            Text("Jacobson's Progressive Muscle Relaxation")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(height: 50)
                        .background(Color(.secondarySystemGroupedBackground))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Button { showASMR = true } label: {
                    VStack(spacing: 0) {
                        Image("ASMR")
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 105, maxHeight: 105)
                            .clipped()
                        
                        VStack(alignment: .center) {
                            Text("ASMR Sounds")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(height: 35)
                        .background(Color(.secondarySystemGroupedBackground))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Button { showDeepFocus = true } label: {
                    VStack(spacing: 0) {
                        Image("DEEPFOCUS")
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(1.3)
                            .offset(x: 5, y: 0)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 105, maxHeight: 105)
                            .clipped()
                        
                        VStack(alignment: .center) {
                            Text("Deep Focus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.9)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(height: 35)
                        .background(Color(.secondarySystemGroupedBackground))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var todayTip: ADHDDailyTip {
        ADHDDailyTip.tip(at: currentTipIndex - 1)
    }

    private var dailyTipRow: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.orange)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Daily ADHD Tip")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(todayTip.category)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            currentTipIndex += 1
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(Circle().fill(Color(.tertiarySystemFill)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Next ADHD Tip")
                }

                Text("\"\(todayTip.quote)\"")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.9))
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)

                Text(todayTip.actionableTip)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

#Preview {
    CalmCentreView()
        .environment(CalmCentreStore.shared)
}
