//
//  InfoView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/15/23.
//

import SwiftUI

struct InfoView: View {
    
    @Environment(\.dismiss) var presentationMode
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            VStack(alignment: .center, spacing: 20, content: {
                HeaderComponent()
                
                Spacer(minLength: 10)
                
                Text("App Info")
                    .fontWeight(.black)
                    .modifier(TitleModifier())
                
                AppInfoView()
                
                Text("Credits")
                    .fontWeight(.black)
                    .modifier(TitleModifier())
                
                CreditView()
                
                Spacer(minLength: 10)
                
                
            })
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.top, 15)
            .padding(.bottom, 25)
            .padding(.horizontal, 25)
        }
        .background(Color(red: 224/255, green: 211/255, blue: 175/255))
    }
}

#Preview {
    InfoView()
}

struct AppInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10, content: {
            RowAppInfo(itemOne: "Application", itemTwo: "ApolloAI")
            RowAppInfo(itemOne: "Compatibility", itemTwo: "iPhone/iPad")
            RowAppInfo(itemOne: "Developer", itemTwo: "Apollo Team")
            RowAppInfo(itemOne: "Designer", itemTwo: "Apollo Team")
            RowAppInfo(itemOne: "Website", itemTwo: "github.com/Kavin-Sits/Apollo")
            RowAppInfo(itemOne: "Version", itemTwo: "1.0.0")
        })
    }
}

struct RowAppInfo: View {
    var itemOne: String
    var itemTwo: String
    
    var body: some View {
        HStack{
            Text(itemOne).foregroundStyle(Color.gray)
            
            Spacer()
            
            Text(itemTwo)
        }
        Divider()
    }
}

struct CreditView: View{
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10, content: {
            Text("Apollo Team Members:").foregroundStyle(Color.gray)
            
            Spacer()
            
            Divider()
            RowAppInfo(itemOne: "Individual Contributor", itemTwo: "Andy Hsu")
            RowAppInfo(itemOne: "Individual Contributor", itemTwo: "Nandini Bhardwaj")
            RowAppInfo(itemOne: "Individual Contributor", itemTwo: "Srihari Manoj")
            RowAppInfo(itemOne: "Individual Contributor", itemTwo: "Kavin Sitsabeshon")
    
        })
        
    }
}

