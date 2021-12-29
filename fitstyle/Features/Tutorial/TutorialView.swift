//
//  TutorialView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 11/25/21.
//

import SwiftUI

struct TutorialView: View {
    @AppStorage("completed_tutorial") private var completedTutorial = false
    
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            GradientView()
            
            GeometryReader { geometry in
                
                VStack(alignment: .center) {
                    
                    HStack() {
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage -= currentPage > 0 ? 1 : 0
                                }
                            }, label: {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(10)
                            })
                        }
                    
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                currentPage = tutorialPages.count - 1
                                completedTutorial = true
                            }
                        }, label: {
                            Text("Skip")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .padding()

                        })
                    }
                
                    
                    TutorialTabView(selection: $currentPage)
                    
                    Button(action: {
                        withAnimation {
                            if currentPage == tutorialPages.count - 1 {
                                completedTutorial = true
                            } else {
                                currentPage += 1
                            }
                        }
                    }, label: {
                        return Text(currentPage == 0 ? "Start" : currentPage == tutorialPages.count - 1 ? "Complete" : "Continue")
                            .foregroundColor(.white)
                            .fontWeight(.heavy)
                            .padding()
                            .frame(width: geometry.size.width * 0.8, height: 60)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(Constants.Theme.cornerRadius)
                            .padding(.horizontal)
                    })
                }
            }
            .padding(.horizontal)
        }
        .transition(.move(edge: .bottom))
        .onAppear(perform: {
            AnalyticsManager.logScreen(screenName: "\(TutorialView.self)", screenClass: "\(TutorialView.self)")
        })
    }
}
