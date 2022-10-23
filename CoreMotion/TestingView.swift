//
//  TestingView.swift
//  Core Motion
//
//  Created by Alex Gregory on 10/23/22.
//  Copyright © 2022 Friedrich Gräter. All rights reserved.
//

import SwiftUI
import Liquid

struct TestingView: View {
    var body: some View {
            ZStack {
                Liquid()
                    .frame(width: 240, height: 140)
                    .foregroundColor(.blue)
                    .opacity(0.3)


                Liquid()
                    .frame(width: 220, height: 120)
                    .foregroundColor(.blue)
                    .opacity(0.6)

                Liquid(samples: 5)
                    .frame(width: 200, height: 100)
                    .foregroundColor(.blue)
                
                Text("Liquid").font(.largeTitle).foregroundColor(.white)
            }
        }
}

struct TestingView_Previews: PreviewProvider {
    static var previews: some View {
        TestingView()
    }
}

