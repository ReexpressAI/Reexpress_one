//
//  StatsTextDisplayOptionsView.swift
//  Reexpress
//
//  Created by A on 9/30/23.
//

import SwiftUI

struct StatsTextDisplayOptionsView: View {
    @AppStorage(REConstants.UserDefaults.statsFontSizeStringKey) var statsFontSize: Double = Double(REConstants.UserDefaults.defaultStatsFontSize)
    
    var statsFont: Font {
        let fontCGFloat = CGFloat(statsFontSize)
        return Font.system(size: max( REConstants.UserDefaults.minStatsFontSize, min(fontCGFloat, REConstants.UserDefaults.maxStatsFontSize) ) )
    }
    
    func updateFontSize(isIncrease: Bool) {
        var updatedFontSize = statsFontSize
        if isIncrease {
            updatedFontSize += 1
            statsFontSize = min(updatedFontSize, REConstants.UserDefaults.maxStatsFontSize)
        } else {
            updatedFontSize -= 1
            statsFontSize = max(updatedFontSize, REConstants.UserDefaults.minStatsFontSize)
        }
    }
     
    func resetDefaults() {
        statsFontSize = Double(REConstants.UserDefaults.defaultStatsFontSize)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Display options")
                    .font(.title2.bold())
                Spacer()
                
                Button {
                    resetDefaults()
                } label: {
                    VStack {
                        Image(systemName: "restart")
                            .font(.title)
                            .foregroundStyle(.blue.gradient)
                        Text("Reset")
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 50, height: 50)
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                }
                .buttonStyle(.borderless)
            }
            
            Grid(verticalSpacing: 10) {
                GridRow {
                    HStack(spacing: 0) {
                        Text("Font size:")
                            .font(REConstants.Fonts.baseFont)
                            .foregroundStyle(.gray)
                        Text(" \(Int(statsFontSize)) pt.")
                            .font(REConstants.Fonts.baseFont)
                    }
                    Text("     ")
                    HStack(alignment: .bottom) {
                        Button {
                            updateFontSize(isIncrease: false)
                        } label: {
                            Image(systemName: "textformat.size.smaller")
                                .font(.title)
                                .foregroundStyle(.blue.gradient)
                            
                        }
                        .buttonStyle(.borderless)
                        Button {
                            updateFontSize(isIncrease: true)
                        } label: {
                            Image(systemName: "textformat.size.larger")
                                .font(.title)
                                .foregroundStyle(.blue.gradient)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .padding()
            .modifier(SimpleBaseBorderModifier())
        }
        .frame(maxWidth: 650)
        .padding([.leading, .trailing, .bottom])
    }
}

