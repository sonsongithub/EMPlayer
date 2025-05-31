//
//  SeriesView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/23.
//

import SwiftUI

#if os(tvOS) || os(iOS)

enum SeasonViewOrientation {
    case vertical
    case horizontal
}

struct TrackableItem: View {
    let id: UUID
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: VisibleItemPreferenceKey.self, value: [id: geometry.frame(in: .global).midX])
        }
    }
}

struct VisibleItemPreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGFloat] = [:]

    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct EpisodeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    @ObservedObject var node: ItemNode
    
    let orientation: SeasonViewOrientation
    
    var body: some View {
        if case .episode(_) = node.item {
            Button {
                drill.stack.append(node)
            } label: {
                switch orientation {
                case .vertical:
                    CardContentView(appState: appState, node: node, id: node.uuid, rotation: .portrait)
                        .padding([.leading, .top, .bottom], 16)
                        .padding(.trailing, 20)
                case .horizontal:
                    CardContentView(appState: appState, node: node, id: node.uuid, rotation: .landscape)
                        .padding([.leading, .top, .bottom], 16)
                        .padding(.trailing, 20)
                }
            }
            .onAppear() {
                Task {
                    await node.updateIfNeeded(using: itemRepository)
                }
            }
        }
    }
}

struct SeasonView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    @ObservedObject var node: ItemNode
    
    let orientation: SeasonViewOrientation
    
    var body: some View {
        switch orientation {
        case .vertical:
            VStack {
                ForEach(node.children, id: \.id) { item in
                    if case .episode(_) = item.item {
                        EpisodeView(node: item, orientation: .horizontal)
                            .environmentObject(appState)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
                            .frame(width: 800, height: 400)
                    }
                }
                .scrollClipDisabled()
#if os(tvOS)
                .buttonStyle(.card)
#endif
            }
            .onAppear() {
                Task {
                    await node.loadChildren(using: itemRepository)
                }
            }
        case .horizontal:
            HStack {
                ForEach(node.children, id: \.id) { item in
                    if case .episode(_) = item.item {
                        EpisodeView(node: item, orientation: .vertical)
                            .environmentObject(appState)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
                            .frame(width: 800, height: 400)
                    }
                }
                .scrollClipDisabled()
#if os(tvOS)
                .buttonStyle(.card)
#endif
            }
            .onAppear() {
                Task {
                    await node.loadChildren(using: itemRepository)
                }
            }
        }
    }
}

struct SeriesInfoView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    @ObservedObject var node: ItemNode
    
    var body: some View {
        if case let .series(baseItem) = node.item {
            HStack(alignment: .top, spacing: 10) {
                AsyncImage(url: baseItem.imageURL(server: appState.server)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFit()
                            .clipped()
                    case .failure:
                        Color.gray
                    default:
                        Color.gray
                    }
                }
                VStack(alignment: .leading, spacing: 20) {
                    Text(baseItem.name)
                        .font(.caption2)
                        .padding(.leading)
                    Text(baseItem.overview ?? "")
                        .font(.footnote)
                        .padding(.leading)
                }
            }
        }
    }
}

class SeriesViewModel: ObservableObject {
    @Published var selectedSeason: ItemNode?
    private var scrollOriginated = false

    func userSelected(season: ItemNode) {
        scrollOriginated = false
        selectedSeason = season
    }

    func scrollDetected(season: ItemNode) {
        guard selectedSeason?.uuid != season.uuid else { return }
        scrollOriginated = true
        selectedSeason = season
    }

    func shouldScroll() -> Bool {
        let should = !scrollOriginated
        scrollOriginated = false
        return should
    }
}

struct RootSeasonView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @EnvironmentObject var viewModel: SeriesViewModel
    
    @ObservedObject var node: ItemNode
    
    let orientation: SeasonViewOrientation
    
    var body: some View {
        ScrollViewReader { proxy in
            Group {
                switch orientation {
                case .horizontal:
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 20) {
                            ForEach(node.children, id: \.id) { season in
                                if case .season(_) = season.item {
                                    SeasonView(node: season, orientation: .horizontal)
                                        .environmentObject(appState)
                                        .environmentObject(itemRepository)
                                        .environmentObject(drill)
                                        .id(season.uuid)
                                }
                            }
                        }
                        .padding(.top)
                        .padding(.horizontal)
                    }
                case .vertical:
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(node.children, id: \.id) { season in
                                if case let .season(base) = season.item {
                                    SeasonView(node: season, orientation: .vertical)
                                        .environmentObject(appState)
                                        .environmentObject(itemRepository)
                                        .environmentObject(drill)
                                        .id(season.uuid)
                                }
                            }
                        }
                        .padding(.top)
                        .padding(.horizontal)
                    }
                }
            }.onChange(of: viewModel.selectedSeason) {
                guard let selectedSeason  = viewModel.selectedSeason else { return }
                if viewModel.shouldScroll() {
                    withAnimation {
                        if orientation == .horizontal {
                            proxy.scrollTo(selectedSeason.uuid, anchor: .leading)
                        } else {
                            proxy.scrollTo(selectedSeason.uuid, anchor: .top)
                        }
                    }
                }
                
            }
            .onPreferenceChange(VisibleItemPreferenceKey.self) { values in
                let center = UIScreen.main.bounds.midX
                if let closest = values.min(by: { abs($0.value - center) < abs($1.value - center) }) {
                    for child in node.children {
                        let season_ids = child.children.map { $0.uuid }
                        if season_ids.contains(closest.key) {
                            viewModel.scrollDetected(season: child)
                            break
                        }
                    }
                }
            }
            .onAppear() {
                Task {
                    await node.loadChildren(using: itemRepository)
                }
            }
        }
    }
}

struct SeriesView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    
    @StateObject var viewModel = SeriesViewModel()
    
    @ObservedObject var node: ItemNode
    @State var dummyID = UUID()
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.layoutDirection) var layoutDirection
    
    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            VStack(alignment: .leading, spacing: 0) {
                SeriesInfoView(node: node)
                    .environmentObject(appState)
                    .environmentObject(itemRepository)
                    .environmentObject(drill)
                    .frame(height: geometry.size.height * 0.3)
                    .padding(20)
                Picker("Season", selection: Binding<ItemNode?>(
                    get: { viewModel.selectedSeason },
                    set: { newValue in
                        if let season = newValue {
                            viewModel.userSelected(season: season)
                        }
                    })
                ) {
                    ForEach(node.children, id: \.customID) { season in
                        Text(season.display())
                            .font(.caption2)
                            .tag(Optional(season))
                    }
                }
                .pickerStyle(.menu)
                .id(self.dummyID)
                
                RootSeasonView(node: node, orientation: isPortrait ? .vertical : .horizontal)
                    .environmentObject(appState)
                    .environmentObject(itemRepository)
                    .environmentObject(drill)
                    .environmentObject(viewModel)
                    .onAppear() {
                        Task {
                            await node.loadChildren(using: itemRepository)
                            DispatchQueue.main.async {
                                viewModel.scrollDetected(season: node.children.first!)
                                dummyID = UUID()
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    let appState = AppState()
    let drill = DrillDownStore()
    let itemRepository = ItemRepository(authProviding: appState)
    let seriesNode = ItemNode.dummySeries()
    SeriesView(node: seriesNode)
        .environmentObject(appState)
        .environmentObject(itemRepository)
        .environmentObject(drill)
}

#endif
