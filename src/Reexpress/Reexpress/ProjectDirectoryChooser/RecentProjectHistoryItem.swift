//
//  RecentProjectHistoryItem.swift
//  Alpha1
//
//  Created by A on 1/22/23.
//

import SwiftUI

// NavigationCookbook
struct RecentProjectHistoryItem: View {
    @Binding var selection: URL?
    var thisURL: URL
    var projectFileName: String {
        thisURL.lastPathComponent
    }
    @Binding var projectDirModel: ProjectDirectoryCoordinator
    var isHistory = false
    
    var body: some View {
        Button {
            projectDirModel.promptAndGetDirectory()

            selection = projectDirModel.proposalURL

            
//            selection = nil //thisURL
        } label: {
            let projectDirectoryName = projectDirModel.getProjectDirectoryStringFromURL(projectURL: thisURL)
            Label(selection: $selection, experience: thisURL, projectDirectoryName: projectDirectoryName, projectFileName: projectFileName)
        }
        .buttonStyle(.plain)
//        .frame(width: 250, height: 100)
    }
}



private struct Label: View {
    @Binding var selection: URL?
    var experience: URL
    @State private var isHovering = false
    var projectDirectoryName = ""
    var projectFileName = ""
    let maxViewLength = 100

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "doc.fill")
                .font(.title)
                .foregroundStyle(shapeStyle(Color.accentColor))
            VStack(alignment: .leading) {
//                Text(experience.localizedName)
                Text(projectFileName.truncateUpToMaxWithEllipsis(maxLength: maxViewLength))
                    .lineLimit(3, reservesSpace: false)
                    //projectDirectoryName)
                    .bold()
                    .foregroundStyle(shapeStyle(Color.primary))
//                Text(experience.localizedDescription)
                Text("\(Image(systemName: "folder.fill")) \(projectDirectoryName.truncateUpToMaxWithEllipsis(maxLength: maxViewLength))")
//                Text(projectDirectoryName.truncateUpToMaxWithEllipsis(maxLength: maxViewLength))
                    .font(.callout)
                    .lineLimit(1, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(shapeStyle(Color.secondary))
            }
        }
        .shadow(radius: selection == experience ? 4 : 0)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selection == experience ?
                      AnyShapeStyle(Color.accentColor) :
                        AnyShapeStyle(BackgroundStyle()))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isHovering ? Color.accentColor : .gray.opacity(0.25))
        }
        .scaleEffect(isHovering ? 1.02 : 1)
        .onHover { isHovering in
            withAnimation {
                self.isHovering = isHovering
            }
        }
    }
    
    func shapeStyle<S: ShapeStyle>(_ style: S) -> some ShapeStyle {
        if selection == experience {
            return AnyShapeStyle(.background)
        } else {
            return AnyShapeStyle(style)
        }
    }
    

}


struct EmptyRecentProjectHistoryItem: View {
    
    var body: some View {
        Button {
        } label: {
            EmptyLabel()
        }
        .buttonStyle(.plain)
        .frame(width: 250, height: 100)
    }
        
}

private struct EmptyLabel: View {
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "folder.fill")
                .font(.title)
                .foregroundStyle(shapeStyle(Color.accentColor))
            VStack(alignment: .leading) {
                Text("")
                    .lineLimit(3, reservesSpace: true)
                    .bold()
                    .foregroundStyle(shapeStyle(Color.primary))
                Text("")
                    .font(.callout)
                    .lineLimit(1, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(shapeStyle(Color.secondary))
            }
            .clipShape(Capsule())
        }
        .shadow(radius: true ? 4 : 0)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AnyShapeStyle(Color.accentColor))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.accentColor)
        }
        .scaleEffect(true ? 1.02 : 1)
    }
    
    func shapeStyle<S: ShapeStyle>(_ style: S) -> some ShapeStyle {
        return AnyShapeStyle(style)
    }
}
