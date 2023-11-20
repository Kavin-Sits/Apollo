//
//  SavedArticle.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 11/20/23.
//

import Foundation
struct SavedArticle {
    
    let title: String
    let url: String
    let description: String?
    let urlToImage: String?
    
    var articleURL: URL {
        URL(string: url)!
    }
    
    var imageURL: URL? {
        guard let urlToImage = urlToImage else{
            return nil
        }
        return URL(string: urlToImage)!
    }
}

extension SavedArticle: Identifiable {
    var id: String {url}
}
