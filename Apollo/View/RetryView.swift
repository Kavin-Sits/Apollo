//
//  RetryView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/11/23.
//

import SwiftUI

struct RetryView: View {
    
    let text: String
    let retryAction: () -> ()
    @EnvironmentObject var nightModeManager: NightModeManager
    
    var body: some View {
        VStack(spacing: 8){
            Text(text)
                .font(.callout)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction, label: {
                Text("Try again")
            })
        }
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
    }
}

#Preview {
    RetryView(text: "") {
    }
}
