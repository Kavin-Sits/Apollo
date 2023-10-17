//
//  TestView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/12/23.
//

import SwiftUI

struct TestView: View {
    var body: some View {
        NavigationStack{
            VStack{
                HeaderView()
                OldCardView(newsImg: "BidenPhoto", title: "How Biden’s Promises to Reverse Trump’s Immigration Policies Crumbled", subTitle: "President Biden has tried to contain a surge of migration by embracing, or at least tolerating, some of his predecessor’s approaches.")
            }
        }
    }
}

#Preview {
    TestView()
}
