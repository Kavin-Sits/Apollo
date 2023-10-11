//
//  SafariView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/10/23.
//

import Foundation
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable  {
    
    let url: URL
    
    func makeUIViewController(context: Context) -> some SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ UIViewController: UIViewControllerType, context: Context){}
}
