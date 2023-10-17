//
//  CreateAccountView.swift
//  Apollo
//
//  Created by Andy Hsu on 10/14/23.
//

import SwiftUI
import CoreLocationUI

let occupationsList = ["accountant", "actor/actress", "artist", "astronaut", "astronomer", "athelete", "banker", "barber", "biologist", "blacksmith", "butler", "cardiologist", "carpenter", "cashier", "chef", "chemist", "contractor", "dentist", "dermatologist", "designer", "doctor", "ecologist", "economist", "engineer", "entrepreneur", "geologist", "geographer", "hairdresser", "intern", "judge", "journalist", "landscaper", "lawyer", "manager", "marketer", "mechanic", "model", "nurse", "optometrist", "paralegal", "pediatrician", "photographer", "physician", "politician", "producer", "professor", "psychologist", "retailer", "salesperson", "scientist", "sheriff", "student", "statistician", "surgeon", "teacher", "technician", "trader", "usher", "veterinarian", "watier/waitress", "writer"]

struct CreateAccountView: View {
    
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var dateOfBirth = ""
    @State private var occupation = ""
    @State private var location = ""
    
    let backgroundColor = Color(red: 148/255, green: 172/255, blue: 255/255)
    
    var body: some View {
        backgroundColor.overlay(
            ZStack {
                VStack(alignment: .center) {
                    Spacer()
                    
                    Button("Create Account") {
                        // TODO add code to segue from this screen to set pfp screen
                    }
                    .frame(height: 200)
                    .cornerRadius(20)
                    .buttonStyle(.borderedProminent)
                }
                
                
                VStack(alignment: .center, spacing: 25) {
                    
                    VStack(alignment: .leading) {
                        
                        Text("Full Name")
                        TextField("", text: $username)
                            .textFieldStyle(.roundedBorder)

                        Text("Email")
                            .padding(.top, 25)
                        TextField("", text: $email)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Password")
                            .padding(.top, 25)
                        TextField("", text: $password)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Date of Birth")
                            .padding(.top, 25)
                        TextField("mm/dd/yyyy", text: $dateOfBirth)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Location")
                            .padding(.top, 25)
                        
//                        LocationButton(.currentLocation) {
//
//                        }
//                        .tint(.white)
//                        .labelStyle(.iconOnly)
                        
                        TextField("", text: $location)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Occupation")
                            .padding(.top, 25)
                            
                        OccupationListDropdownMenu() {
                            option in
                            self.occupation = option
                        }
                        .frame(width: 320)
                        
                        Spacer()
                    }
                }
                .padding(.top, 100)
                .padding(.bottom, 70)
                .frame(width: 320)
            }
            
        )
        .ignoresSafeArea()
    }
}

struct OccupationListDropdownMenu: View {
    
    @State var presentOptions: Bool = false
    @State var selectedOption = ""
    
    let setOccupationVar: (_ option: String) -> Void
    let placeholder: String = "Select your occupation"
    
    var body: some View {
        Button(action: {
            withAnimation{
                self.presentOptions.toggle()
            }
        }) {
            HStack {
                TextField(selectedOption == "" ? placeholder : selectedOption, text: $selectedOption)
                    .frame(height: 30)
                    .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                
            }
        }
        .background(Color.white)
        .cornerRadius(5)
        .overlay(alignment: .top) {
            VStack {
                if self.presentOptions {
                    Spacer(minLength: 35)
                    OccupationListDropdownMenuList(options: occupationsList) {
                        option in
                        self.presentOptions = false
                        self.selectedOption = option
                        setOccupationVar(option)
                    }
                }
                
            }
        }
    }
}

struct OccupationListDropdownMenuList: View {
    
    let options: [String]
    
    let onSelectedAction: (_ option: String) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(options, id: \.self) {
                    option in
                    Button (action: {
                        onSelectedAction(option)
                    }) {
                        Text(option)
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .frame(height: 150)
        .padding(.vertical, 5)
        .background(.white)
        .cornerRadius(5)
    }
}

#Preview {
    CreateAccountView()
}
