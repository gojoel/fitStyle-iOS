//
//  SettingsView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 10/26/21.
//

import Foundation
import SwiftUI
import Combine
import MessageUI

struct SettingsView: View {
    
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @ObservedObject var viewModel: SettingsViewModel

    @State var userId: String = ""
    
    @State var appVersion: String = ""
    
    @State var result: Result<MFMailComposeResult, Error>? = nil
    
    @State var isShowingMailView = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("User Id")
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: Alignment.leading)

                            Text(viewModel.userId)
                                .frame(maxWidth: .infinity, alignment: Alignment.trailing)
                    }
                    
                    HStack {
                        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

                        Text("Version")
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: Alignment.leading)

                        Text(appVersion ?? "")
                            .frame(maxWidth: .infinity, alignment: Alignment.trailing)
                    }
                }
                
                if MFMailComposeViewController.canSendMail() {
                    Section(header: Text("Feedback")) {
                        Button(action: {
                            self.isShowingMailView.toggle()
                        }, label: {
                            HStack {
                                Text("Send Us Feedback")
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: Alignment.leading)
                                
                                Image(systemName: "chevron.forward")
                                    .frame(width: 20, height: 20, alignment: Alignment.trailing)
                            }
                        })
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Constants.Theme.createBackButton(presentation: self.presentationMode))
        .sheet(isPresented: $isShowingMailView) {
            MailView(isShowing: self.$isShowingMailView, result: self.$result)
        }
    }
}
