//
//  HeaderView.swift
//  Apollo
//
//  Created by Kavin Sitsabeshon on 10/8/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct HeaderView: View {
    
    @State private var weekdayProgress: Float = 0
    @Binding var showSettingsView:Bool
    let haptics = UINotificationFeedbackGenerator()
    @State private var image: UIImage? = nil
    @State private var cancellable: AnyCancellable? = nil
    @EnvironmentObject var nightModeManager: NightModeManager
    
    var body: some View {
        VStack(spacing: 0){
            HStack{
                VStack{
                    HStack(spacing: 15){
                        Text("Sun")
                        Text("Mon")
                        Text("Tues")
                        Text("Wed")
                        Text("Thurs")
                        Text("Fri")
                        Text("Sat")
                    }
                    ProgressView(value: weekdayProgress, total: 1)
                        .progressViewStyle(LinearProgressViewStyle())
                        .onAppear{
                            updateWeekdayProgress()
                        }
                }
                
                Spacer()
                
                Button(action: {
                    self.showSettingsView.toggle()
                    self.haptics.notificationOccurred(.success)
                }, label: {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width / 10, height: UIScreen.main.bounds.width / 10)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            .shadow(radius: 5)
                    } else {
                        Image(systemName: "person.circle")
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width / 10, height: UIScreen.main.bounds.width / 10)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            .shadow(radius: 5)
                    }
                })
                .accentColor(Color.primary)
                .sheet(isPresented: $showSettingsView, content: {
                    MainSettingsView()
                        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
                })
            }
            .padding(10)
            Text("What news would you like to view today?")
                .font(.title3)
                .multilineTextAlignment(.center)
                .bold()
        }
        .onAppear() {
            loadProfilePhoto()
        }
        .preferredColorScheme(nightModeManager.isNightMode ? .dark : .light)
    }
    
    func updateWeekdayProgress() {
        let currentDate = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)

        weekdayProgress = Float(weekday) / 7.0
    }
    
    func loadProfilePhoto() {
        Firestore.firestore().collection("users").document(Auth.auth().currentUser?.email ?? "").getDocument { (document, error) in
            if let document = document, document.exists {
                if let urlString = document.data()?["profilePhotoURL"] as? String, let url = URL(string: urlString) {
                    self.cancellable = URLSession.shared.dataTaskPublisher(for: url)
                        .map { UIImage(data: $0.data) }
                        .replaceError(with: nil)
                        .receive(on: DispatchQueue.main)
                        .sink { downloadedImage in
                            self.image = downloadedImage
                        }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}

