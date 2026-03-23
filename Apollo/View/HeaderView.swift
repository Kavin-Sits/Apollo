//
//  HeaderView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/8/23.
//

import SwiftUI

struct HeaderView: View {
    
    @State private var weekdayProgress: Float = 0
    @Binding var showSettingsView:Bool
    let haptics = UINotificationFeedbackGenerator()
    @State private var image: UIImage? = nil
    @EnvironmentObject var nightModeManager: NightModeManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionEyebrow(text: "Daily Brief")

                    Text("Swipe through stories tuned to your mood.")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppStyle.surfaceTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Save the strong picks, skip the noise, and open any card when you want the full article.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppStyle.surfaceTextSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                                Text(day)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppStyle.surfaceTextSecondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        ProgressView(value: weekdayProgress, total: 1)
                            .tint(AppStyle.accentSecondary)
                            .onAppear {
                                updateWeekdayProgress()
                            }
                    }
                }

                Button(action: {
                    self.showSettingsView.toggle()
                    self.haptics.notificationOccurred(.success)
                }, label: {
                    Group {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .padding(10)
                                .foregroundStyle(AppStyle.surfaceTextPrimary)
                        }
                    }
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(Color.white.opacity(0.68)))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
                })
                .buttonStyle(.plain)
                .sheet(isPresented: $showSettingsView, content: {
                    MainSettingsView()
                        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
                })
            }
            .padding(20)
            .glassPanel()
        }
        .onAppear() {
            loadProfilePhoto()
        }
        .onReceive(NotificationCenter.default.publisher(for: .profilePhotoDidChange)) { _ in
            loadProfilePhoto()
        }
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
    }
    
    func updateWeekdayProgress() {
        let currentDate = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)

        weekdayProgress = Float(max(weekday - 1, 1)) / 7.0
    }
    
    func loadProfilePhoto() {
        if let image = AppSession.loadProfilePhoto() {
            self.image = image
        }
    }
}
