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
    
    var body: some View {
        VStack(spacing: 8){
            Text(text)
                .font(.callout)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction, label: {
                Text("Try again")
            })
        }
    }
}

#Preview {
    RetryView(text: "") {
    }
}
