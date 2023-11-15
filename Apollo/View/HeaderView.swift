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
    
    var body: some View {
        VStack(spacing: 0){
            HStack{
                VStack{
                    HStack(spacing: 15){
                        Text("Sun")
                        Text("Mon")
                        Text("Tues")
                        Text("Wed")
                        Text("Thurs")
                        Text("Fri")
                        Text("Sat")
                    }
                    ProgressView(value: weekdayProgress, total: 1)
                        .progressViewStyle(LinearProgressViewStyle())
                        .onAppear{
                            updateWeekdayProgress()
                        }
                }
                
                Spacer()
                
                Button(action: {
                    self.showSettingsView.toggle()
                    self.haptics.notificationOccurred(.success)
                }, label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 25, weight: .regular))
                })
                .accentColor(Color.primary)
                .sheet(isPresented: $showSettingsView, content: {
                    MainSettingsView()
                })
            }
            .padding(10)
            Text("What news would you like to view today?")
                .font(.title3)
                .multilineTextAlignment(.center)
                .bold()
        }
    }
    
    func updateWeekdayProgress() {
        let currentDate = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)

        weekdayProgress = Float(weekday) / 7.0
    }
}

