//
//  UncertaintyChart+ViewModel.swift
//  Alpha1
//
//  Created by A on 5/2/23.
//

import SwiftUI

extension UncertaintyChart {
    @MainActor class ViewModel: ObservableObject {
        @Published var selectedElement: String?
        @Published var isHovering = false
        
        @Published var selectedTappedElement: String?
        
        //@Published var searchParametersPopoverShowing: Bool = false
        
        // For controls
        let buttonDividerHeight: CGFloat = 40
        

    }
}
