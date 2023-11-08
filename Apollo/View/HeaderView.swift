//
//  HeaderView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/8/23.
//

import SwiftUI

struct HeaderView: View {
    
    @Binding var showSettingsView:Bool
    let haptics = UINotificationFeedbackGenerator()
    
    var body: some View {
        VStack(spacing: 0){
            HStack{
                VStack{
                    HStack{
                        Text("Mon")
                        Text("Tues")
                        Text("Wed")
                        Text("Thurs")
                        Text("Fri")
                        Text("Sat")
                        Text("Sun")
                    }
                    ProgressView(value: 0.25)
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
}

