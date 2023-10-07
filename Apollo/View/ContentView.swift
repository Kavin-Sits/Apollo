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
        CardView()
    }

}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
