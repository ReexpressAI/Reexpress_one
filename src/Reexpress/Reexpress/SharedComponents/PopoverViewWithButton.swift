//
//  PopoverViewWithButton.swift
//  Alpha1
//
//  Created by A on 7/26/23.
//

import SwiftUI

struct PopoverViewWithButton: View {
    @Binding var isShowingInfoPopover: Bool
    var popoverViewText: String = ""
    var optionalSubText: String? = nil
    var arrowEdge: Edge = .trailing
    
    var body: some View {
        Button {
            isShowingInfoPopover.toggle()
        } label: {
            Image(systemName: "info.circle.fill")
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $isShowingInfoPopover, arrowEdge: arrowEdge) {
            PopoverView(popoverViewText: popoverViewText, optionalSubText: optionalSubText)
        }
    }
}


struct PopoverViewWithButtonLocalState: View {
    @State var isShowingInfoPopover: Bool = false
    var popoverViewText: String = ""
    var optionalSubText: String? = nil
    var arrowEdge: Edge = .trailing
    
    var body: some View {
        Button {
            isShowingInfoPopover.toggle()
        } label: {
            Image(systemName: "info.circle.fill")
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $isShowingInfoPopover, arrowEdge: arrowEdge) {
            PopoverView(popoverViewText: popoverViewText, optionalSubText: optionalSubText)
        }
    }
}
//struct PopoverViewWithButton_Previews: PreviewProvider {
//    static var previews: some View {
//        PopoverViewWithButton()
//    }
//}

struct PopoverViewWithButtonLocalStateOptions: View {  // This can render markdown
    @State var isShowingInfoPopover: Bool = false
    var popoverViewText: String = ""
    var optionalSubText: String? = nil
    var arrowEdge: Edge = .trailing
    var frameWidth: CGFloat = 200
    var body: some View {
        Button {
            isShowingInfoPopover.toggle()
        } label: {
            Image(systemName: "info.circle.fill")
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $isShowingInfoPopover, arrowEdge: arrowEdge) {
            PopoverViewWithOptions(popoverViewText: popoverViewText, optionalSubText: optionalSubText, frameWidth: frameWidth)
        }
    }
}
struct PopoverViewWithOptions: View { // This can render markdown because of .init
    var popoverViewText = ""
    var optionalSubText: String? = nil
    var frameWidth: CGFloat = 200
    var body: some View {
        VStack(alignment: .leading) {
            Text(.init(popoverViewText))
            if let subText = optionalSubText {
                Text("")
                Text(.init(subText))
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .frame(width: frameWidth)
    }
}


struct PopoverViewWithButtonLocalStateOptionsLocalizedString: View {  // This can render markdown
    @State var isShowingInfoPopover: Bool = false
    var popoverViewText: LocalizedStringKey = ""
    var optionalSubText: LocalizedStringKey? = nil
    var arrowEdge: Edge = .trailing
    var frameWidth: CGFloat = 350
    var body: some View {
        Button {
            isShowingInfoPopover.toggle()
        } label: {
            Image(systemName: "info.circle.fill")
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $isShowingInfoPopover, arrowEdge: arrowEdge) {
            PopoverViewWithOptionsLocalizedString(popoverViewText: popoverViewText, optionalSubText: optionalSubText, frameWidth: frameWidth)
        }
    }
}
struct PopoverViewWithOptionsLocalizedString: View { // This can render markdown because of .init
    var popoverViewText: LocalizedStringKey = ""
    var optionalSubText: LocalizedStringKey? = nil
    var frameWidth: CGFloat = 350
    var body: some View {
        VStack(alignment: .leading) {
            Text(popoverViewText)
            if let subText = optionalSubText {
                Text("")
                Text(subText)
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .frame(width: frameWidth)
    }
}

/*struct PopoverViewWithButtonLocalStateOptions_TextStruct: View {
    @State var isShowingInfoPopover: Bool = false
    var popoverViewText: Text = Text("")
    var optionalSubText: Text? = nil
    var arrowEdge: Edge = .trailing
    var frameWidth: CGFloat = 350
    var body: some View {
        Button {
            isShowingInfoPopover.toggle()
        } label: {
            Image(systemName: "info.circle.fill")
        }
        .buttonStyle(.borderless)
        .popover(isPresented: $isShowingInfoPopover, arrowEdge: arrowEdge) {
            PopoverViewWithOptions_TextStruct(popoverViewText: popoverViewText, optionalSubText: optionalSubText, frameWidth: frameWidth)
        }
    }
}
struct PopoverViewWithOptions_TextStruct: View { // This can render markdown because of .init
    var popoverViewText: Text = Text("")
    var optionalSubText: Text? = nil
    var frameWidth: CGFloat = 350
    var body: some View {
        VStack(alignment: .leading) {
            popoverViewText
            if let subText = optionalSubText {
                Text("")
                optionalSubText
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .frame(width: frameWidth)
    }
}*/
