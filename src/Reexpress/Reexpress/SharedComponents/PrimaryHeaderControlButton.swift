//
//  PrimaryHeaderControlButton.swift
//  Alpha1
//
//  Created by A on 6/24/23.
//

import SwiftUI

/// This is necessary to align the text at the bottom of the button across the horizontal line of buttons. Based on https://developer.apple.com/documentation/swiftui/aligning-views-across-stacks
extension VerticalAlignment {
    /// A custom alignment for PrimaryHeaderControlButton
    private struct PrimaryHeaderControlButtonAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            // Default alignment if no guides are set.
            context[VerticalAlignment.lastTextBaseline]
        }
    }
    /// A guide for aligning titles.
    static let primaryHeaderControlButtonAlignmentGuide = VerticalAlignment(
        PrimaryHeaderControlButtonAlignment.self
    )
}

struct PrimaryHeaderControlButton: View {
    @Binding var isSelected: Bool
    var exclusiveSelection: Bool = false
    
    var buttonImageName: String
    var buttonTextCaption: String
    
    var buttonForegroundStyle: AnyShapeStyle = AnyShapeStyle(Color.blue.gradient)
    // Shared constants:
    let buttonFrameWidth: CGFloat = 70+10
    let buttonFrameHeight: CGFloat = 40+30
    let buttonPadding = EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
    
    var body: some View {
        VStack {
            VStack {
                Image(systemName: buttonImageName)
                    .font(.title)
                    .foregroundStyle(buttonForegroundStyle)
                Text(buttonTextCaption)
//                    .foregroundStyle(.secondary)
                    .foregroundStyle(.gray)
                    .alignmentGuide(.primaryHeaderControlButtonAlignmentGuide) { context in
                        context[.lastTextBaseline]
                    }
            }
            .padding(buttonPadding)
                if exclusiveSelection {
                    if isSelected {
                        VStack {
                            Image(systemName: "circle.fill")
                        }
                        .foregroundStyle(Color.blue.gradient)
                        .font(.system(size: 10))
                    } else {
                        VStack {
                            Image(systemName: "circle.fill")
                        }
                        .foregroundStyle(Color.blue.gradient)
                        .font(.system(size: 10))
                        .hidden()
                    }
                } else {
                    VStack {
                        Image(systemName: "circle.fill")
                    }
                    .foregroundStyle(isSelected ? Color.blue.gradient : Color.gray.gradient)
                    .font(.system(size: 10))
                }
        }
        .frame(width: buttonFrameWidth, height: buttonFrameHeight)
    }
}
