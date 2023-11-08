//
//  AuthViewModel.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/7/23.
//

import Foundation
class AuthViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var username: String = ""
    @Published var password: String = ""
    
    func logOut(){
        self.username = ""
        self.password = ""
        self.isLoggedIn = false
    }
    
    func logIn(){
        self.isLoggedIn = true
    }
}
