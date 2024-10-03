//
//  ProjectDetailsView.swift
//  Alpha1
//
//  Created by A on 7/15/23.
//

import SwiftUI

struct ProjectDetailsView: View {
    var onlyShowTask: Bool = false
    
    @EnvironmentObject var initialSetupDataController: InitialSetupDataController
    
    var body: some View {
        VStack(alignment: .leading) {
                Text("Project details")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 5) {
                GridRow {
                    Text("Task:")
                        .foregroundColor(.secondary)
                        .gridColumnAlignment(.trailing)
                    HStack {
                        Text("\(initialSetupDataController.numberOfClasses == 2 ? "Binary classification (+search+reranking)" : "Multi-class classification (\(initialSetupDataController.numberOfClasses)-class) (+search+reranking)")")
                        Spacer()
                    }
                    //.frame(width: 275)
                    .gridColumnAlignment(.leading)
                    
                }
                GridRow {
                    Text("Language:")
                        .foregroundColor(.secondary)
                    HStack {
                        Text("Multilingual")
                        PopoverViewWithButtonLocalStateOptions(popoverViewText: "The model accepts any language written left-to-right (English, French, German, Japanese, Norwegian, etc.), but it is most effective on English.", optionalSubText: "Less common languages may require more training data to achieve similar effectiveness. Prompts, if used, are most effective when written in English, regardless of the document's language.", frameWidth: 350)
                    }
                    .opacity(onlyShowTask ? 0.0 : 1.0)
                }
                GridRow {
                    Text("Model:")
                        .foregroundColor(.secondary)
                    Text(
                        SentencepieceConstants.getModelGroupName(modelGroup: initialSetupDataController.modelGroup)
                    )
                    .monospaced()
                    .opacity(onlyShowTask ? 0.0 : 1.0)
                }
                
                GridRow {
                    Text("Parameters:")
                        .foregroundColor(.secondary)
                    Text(
                        SentencepieceConstants.getModelParameterCountForDisplay(modelGroup: initialSetupDataController.modelGroup)
                    )
                    .opacity(onlyShowTask ? 0.0 : 1.0)
                }
                GridRow {
                    Text("Max length:")
                        .foregroundColor(.secondary)
                    HStack {
                        Text(
                            String(SentencepieceConstants.getModelGroupMaxTokens(modelGroup: initialSetupDataController.modelGroup)) + " tokens"
                        )
                        PopoverViewWithButtonLocalStateOptions(popoverViewText: "A token consists of one or more characters. Common words may correspond to a single token; less common words are broken into multiple tokens for improved modeling effectiveness.", optionalSubText: "For reference, the *Gettysburg Address* (Abraham Lincoln, 1863) is around 330 tokens.", frameWidth: 350)
                    }
                    .opacity(onlyShowTask ? 0.0 : 1.0)
                }
            }
            
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill( 
                        AnyShapeStyle(BackgroundStyle()))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.gray)
                    .opacity(0.5)
            }
        }
        .modifier(CreateProjectBaselineFontViewModifier())
        
    }
}

struct ProjectDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetailsView()
    }
}
