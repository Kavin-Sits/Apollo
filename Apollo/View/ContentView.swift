//
//  ContentView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/6/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        CardView(newsImg: "BidenPhoto", title: "How Biden’s Promises to Reverse Trump’s Immigration Policies Crumbled", subTitle: "President Biden has tried to contain a surge of migration by embracing, or at least tolerating, some of his predecessor’s approaches.")
    }

}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
