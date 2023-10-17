//
//  HeaderView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/8/23.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        NavigationStack {
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
                    
                    NavigationLink{
                        MainSettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 25, weight: .regular))
                    }
                    .accentColor(Color.primary)
                }
                .padding(10)
                Text("What news would you like to view today?")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .bold()
            }
        }
    }
}

#Preview("Header View", traits: .fixedLayout(width: 375, height: 80)) {
    HeaderView()
}
