//
//  GradientView.swift
//  fitstyle
//
//  Created by Joel Goncalves on 11/25/21.
//

import SwiftUI

struct GradientView: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors:
                                            [Constants.Theme.mainAppColor,
                                             Constants.Theme.secondaryAppColor])
                       , startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
    }
}

struct GradientView_Previews: PreviewProvider {
    static var previews: some View {
        GradientView()
    }
}
