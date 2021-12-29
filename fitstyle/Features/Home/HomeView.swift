//
//  HomeView.swift
//  fitsyle
//
//  Created by Joel Goncalves on 9/28/21.
//

import SwiftUI
import Combine

struct HomeView: View {
    
    @ObservedObject var viewModel = HomeViewModel()
    
    @State var styleListActive : Bool = false
    
    @State var styledListActive : Bool = false
        
    let iconSize: CGFloat = 25.0
    
    let buttonWidthMultiplier: CGFloat = 0.75
        
    var body: some View {
        NavigationView {
            content
                .navigationBarHidden(true)
                .onAppear(perform: {
                    AnalyticsManager.logScreen(screenName: "\(HomeView.self)", screenClass: "\(HomeView.self)")
                })
        }
    }
    
    private var content: some View {
        GeometryReader { geometry in
            VStack(alignment: .center, spacing: 20) {
                
                NavigationLink(destination: StyleListView(viewModel: StyleListViewModel(), homeViewActive: self.$styleListActive), isActive: self.$styleListActive, label: {
                                HStack() {
                                    Image(systemName: "arrow.forward")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.white)
                                        .frame(width: Constants.Theme.buttonIconSize, height: Constants.Theme.buttonIconSize)

                                    Text("Get Started!")
                                        .fontWeight(.semibold)
                                        .frame(minWidth: 0, maxWidth: geometry.size.width * buttonWidthMultiplier)
                                }
                }).isDetailLink(false)
                .buttonStyle(Constants.Theme.StyledButton())
                
                NavigationLink(
                    destination: StyledImagesListView(viewModel: StyledImagesViewModel(), homeViewActive: self.$styledListActive),
                    isActive: self.$styledListActive
                ) {
                    HStack() {
                        Image(systemName: "photo.on.rectangle")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: Constants.Theme.buttonIconSize, height: Constants.Theme.buttonIconSize)

                        Text("My Images")
                            .fontWeight(.semibold)
                            .frame(minWidth: 0, maxWidth: geometry.size.width * buttonWidthMultiplier)
                    }
                }
                .isDetailLink(false)
                .buttonStyle(Constants.Theme.StyledButton())
                
                NavigationLink(
                    destination: SettingsView(viewModel: SettingsViewModel())
                ) {
                    HStack() {
                        Image(systemName: "gearshape")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: Constants.Theme.buttonIconSize, height: Constants.Theme.buttonIconSize)

                        Text("Settings")
                            .fontWeight(.semibold)
                            .frame(minWidth: 0, maxWidth: geometry.size.width * buttonWidthMultiplier)
                    }
                }
                .buttonStyle(Constants.Theme.StyledButton())
                
            }.frame(
                maxWidth: geometry.size.width,
                maxHeight: geometry.size.height
            )
        }
    }
}
