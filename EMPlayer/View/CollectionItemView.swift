//
//  CollectionItemView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/22.
//

import SwiftUI

struct CollectionItemView: View {
    let item: BaseItem
    let appState: AppState
    let width = CGFloat(100)
    let height = CGFloat(300)
    var body: some View {
        GeometryReader { geometry in
            NavigationLink(destination: nextView(item: item).environmentObject(appState)) {
                VStack {
                    if let url = item.imageURL(server: appState.server) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .foregroundColor(.gray)
                    }
                    Text(item.name)
                        .font(.title2)
                        .dynamicTypeSize(.xSmall) 
                }
            }
        }
    }
    
    @ViewBuilder
    func nextView(item: BaseItem) -> some View {
        if item.type == .collectionFolder || item.type == .boxSet || item.type == .season {
            CollectionView(item: item)
        } else if item.type == .series {
            SeriesView(series: item).environmentObject(appState)
        } else {
            DetailView(movieID: item.id)
        }
    }
}

struct CollectionItemView_Previews: PreviewProvider {
    static var previews: some View {
        CollectionItemView(item: BaseItem.dummy, appState: AppState())
        .frame(width: 200, height: 400) // View自体のサイズを制限
        .previewLayout(.sizeThatFits)
    }
}
