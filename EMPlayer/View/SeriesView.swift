//
//  SeriesView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/23.
//

import SwiftUI

#if os(tvOS) || os(iOS)

struct AdaptiveScrollLayout<Content: View>: View {

    let direction: SeriesViewStrategy.ScrollDirection
    let spacing: CGFloat
    let height: CGFloat?
    let content: () -> Content

    init(direction: SeriesViewStrategy.ScrollDirection, spacing: CGFloat = 10, height: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.direction = direction
        self.spacing = spacing
        self.height = height
        self.content = content
    }

    var body: some View {
        Group {
            switch direction {
            case .horizontal:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        content()
                    }
                    .padding(.horizontal, spacing)
                }
                .frame(height: height)

            case .vertical:
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: spacing) {
                        content()
                    }
                    .padding(.vertical, spacing)
                }
            }
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
    @Environment(\.seriesViewStrategy) var strategy
    
    @ObservedObject var node: ItemNode
    
    var body: some View {
        GeometryReader { geometry in
            if case .episode(_) = node.item {
                Button {
                    drill.stack.append(node)
                } label: {
                    switch strategy.episode.layout {
                    case .landscape:
                        EpisodeContent(appState: appState, node: node, id: node.uuid, rotation: .landscape)
                            .padding(strategy.episode.padding)
                    case .portrait:
                        EpisodeContent(appState: appState, node: node, id: node.uuid, rotation: .portrait)
                            .padding(strategy.episode.padding)
                    }
                }
                .onAppear() {
                    Task {
                        await node.updateIfNeeded(using: itemRepository)
                    }
                }
                .preference(key: VisibleItemPreferenceKey.self, value: (strategy.scrollDirection == .horizontal) ? [node.uuid: geometry.frame(in: .global).midX] : [node.uuid: geometry.frame(in: .global).midY])
            }
        }
    }
}

struct SeasonView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @Environment(\.seriesViewStrategy) var strategy
    @ObservedObject var node: ItemNode

    var body: some View {
        AdaptiveScrollLayout(direction: strategy.scrollDirection,
                             spacing: strategy.episode.space,
                             height: strategy.scrollDirection == .horizontal ? strategy.episode.height : nil) {
            ForEach(node.children, id: \.id) { item in
                if case .episode(_) = item.item {
                    EpisodeView(node: item)
                        .environmentObject(appState)
                        .environmentObject(itemRepository)
                        .environmentObject(drill)
                        .environment(\.seriesViewStrategy, strategy)
                        .frame(width: strategy.episode.width, height: strategy.episode.height)
                }
            }
        }
        .scrollClipDisabled()
        .padding(strategy.episodePadding)
#if os(tvOS)
        .buttonStyle(.card)
#endif
        .task {
            await node.loadChildren(using: itemRepository)
        }
    }
}

func getInfos(baseItem: BaseItem) -> [String] {
    var infos: [String] = []
    if let productionYear = baseItem.productionYear {
        infos.append("\(productionYear)")
    }
    if let childCount = baseItem.childCount, childCount > 0 {
        if childCount == 1 {
            infos.append("\(childCount) season")
        } else {
            infos.append("\(childCount) seasons")
        }
    }
    return infos
}

struct SeriesInfo: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var itemRepository: ItemRepository
    @EnvironmentObject var drill: DrillDownStore
    @Environment(\.seriesViewStrategy) var strategy
    @ObservedObject var node: ItemNode
    
    var body: some View {
        if case let .series(baseItem) = node.item {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    if strategy.info.hasImage {
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
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(baseItem.name)
                            .font(strategy.info.titleFont)
                            .bold()
                            .padding()
                        HStack {
                            ForEach(getInfos(baseItem: baseItem), id: \.self) { info in
                                Text(info)
                            }
                        }
                        .padding()
                        Text(baseItem.overview ?? "")
                            .font(strategy.info.overviewFont)
                            .padding()
                    }
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
    @Environment(\.seriesViewStrategy) var parentStrategy
    @ObservedObject var node: ItemNode
    
    var body: some View {
        ScrollViewReader { proxy in
            Group {
                switch parentStrategy.scrollDirection {
                case .horizontal:
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(node.children, id: \.id) { season in
                                if case .season(_) = season.item {
                                    SeasonView(node: season)
                                        .environment(\.seriesViewStrategy, parentStrategy)
                                        .id(season.uuid)
                                }
                            }
                        }
                    }
                case .vertical:
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(node.children, id: \.id) { season in
                                if case .season(_) = season.item {
                                    SeasonView(node: season)
                                        .environment(\.seriesViewStrategy, parentStrategy)
                                        .id(season.uuid)
                                }
                            }
                        }
                    }
                }
            }.onChange(of: viewModel.selectedSeason) {
                guard let selectedSeason  = viewModel.selectedSeason else { return }
                if viewModel.shouldScroll() {
                    withAnimation {
                        if parentStrategy.scrollDirection == .horizontal {
                            proxy.scrollTo(selectedSeason.uuid, anchor: .leading)
                        } else {
                            proxy.scrollTo(selectedSeason.uuid, anchor: .top)
                        }
                    }
                }
                
            }
            .onPreferenceChange(VisibleItemPreferenceKey.self) { values in
                let center = (parentStrategy.scrollDirection == .horizontal) ? UIScreen.main.bounds.midX : UIScreen.main.bounds.midY
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
    @State var tabBarVisibility: Visibility = .visible
    
    @StateObject var viewModel = SeriesViewModel()
    
    @ObservedObject var node: ItemNode
    @State var dummyID = UUID()
    
    var body: some View {
        GeometryReader { geometry in
            let strategy = SeriesViewStrategy.resolve(using: geometry)
            VStack(alignment: .leading, spacing: 0) {
                SeriesInfo(node: node)
                    .frame(height: strategy.info.height)
                    .environment(\.seriesViewStrategy, strategy)
                    .padding(.horizontal, strategy.info.horizontalPadding)
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
                .padding(.top, strategy.pickerMarginTop)
                .padding(.bottom, strategy.pickerMarginBottom)
                
                RootSeasonView(node: node)
                    .environmentObject(viewModel)
                    .environment(\.seriesViewStrategy, strategy)
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
            .padding(strategy.padding)
        }
    }
}

#Preview {
    let appState = AppState()
    let drill = DrillDownStore()
    let itemRepository = ItemRepository(authProviding: appState)
    let seriesNode = ItemNode.dummySeries()
    NavigationStack {
        SeriesView(node: seriesNode)
            .environmentObject(appState)
            .environmentObject(itemRepository)
            .environmentObject(drill)
        #if os(tvOS)
//            .ignoresSafeArea(edges: [.top])
        #endif
    }
}

#endif
