//
//  SeriesView.swift
//  EMPlayer
//
//  Created by sonson on 2025/02/23.
//

import SwiftUI

#if os(tvOS) || os(iOS)


struct SeriesViewStrategy {
    
    enum ScrollDirection {
        case vertical
        case horizontal
    }
    enum EpisodeLayout {
        case portrait
        case landscape
    }

    let scrollDirection: ScrollDirection
    let episodeLayout: EpisodeLayout
    
    let infoViewHeight: CGFloat
    let episodeWidth: CGFloat
    let episodeHeight: CGFloat

    init(isPad: Bool, isPortrait: Bool, size: CGSize) {
        #if os(iOS)
        if isPad {
            scrollDirection = isPortrait ? .vertical : .horizontal
            episodeLayout = isPortrait ? .landscape : .portrait
            if isPortrait {
                infoViewHeight = size.height * 0.3
                episodeWidth = size.width
                episodeHeight = 200
            } else {
                infoViewHeight = size.height * 0.3
                episodeWidth = 400
                episodeHeight = size.height * 0.6
            }
        } else {
            scrollDirection = isPortrait ? .vertical : .horizontal
            episodeLayout = isPortrait ? .landscape : .landscape
            if isPortrait {
                infoViewHeight = size.height * 0.3
                episodeWidth = size.width
                episodeHeight = 150
            } else {
                infoViewHeight = size.height * 0.3
                episodeWidth = 400
                episodeHeight = size.height * 0.6
            }
        }
        #else
        scrollDirection = .horizontal
        episodeLayout = .portrait
        infoViewHeight = size.height * 0.3
        episodeWidth = 400
        episodeHeight = size.height * 0.6
        #endif
    }

    static let `default` = SeriesViewStrategy(isPad: false, isPortrait: true, size: CGSize(width: 1920, height: 800))
    
    static func resolve(using geometry: GeometryProxy) -> SeriesViewStrategy {
        let size = geometry.size
        let isPortrait = size.height >= size.width
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        return SeriesViewStrategy(isPad: isPad, isPortrait: isPortrait, size: size)
    }
}

private struct SeriesViewStrategyKey: EnvironmentKey {
    static let defaultValue: SeriesViewStrategy = .default
}

extension EnvironmentValues {
    var seriesViewStrategy: SeriesViewStrategy {
        get { self[SeriesViewStrategyKey.self] }
        set { self[SeriesViewStrategyKey.self] = newValue }
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
                    switch strategy.episodeLayout {
                    case .landscape:
                        CardContentView(appState: appState, node: node, id: node.uuid, rotation: .landscape)
                            .padding([.leading, .top, .bottom], 16)
                            .padding(.trailing, 20)
                    case .portrait:
                        CardContentView(appState: appState, node: node, id: node.uuid, rotation: .portrait)
                            .padding([.leading, .top, .bottom], 16)
                            .padding(.trailing, 20)
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
        switch strategy.scrollDirection {
        case .vertical:
            VStack {
                ForEach(node.children, id: \.id) { item in
                    if case .episode(_) = item.item {
                        EpisodeView(node: item)
                            .environmentObject(appState)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
                            .environment(\.seriesViewStrategy, strategy)
                            .frame(width: strategy.episodeWidth, height: strategy.episodeHeight)
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
                        EpisodeView(node: item)
                            .environmentObject(appState)
                            .environmentObject(itemRepository)
                            .environmentObject(drill)
                            .environment(\.seriesViewStrategy, strategy)
                            .frame(width: strategy.episodeWidth, height: strategy.episodeHeight)
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
    @Environment(\.seriesViewStrategy) var strategy
    @ObservedObject var node: ItemNode
    
    var body: some View {
        if case let .series(baseItem) = node.item {
            HStack(alignment: .top, spacing: 0) {
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
                VStack(alignment: .leading, spacing: 0) {
//                    Text(baseItem.name)
//                        .font(.caption2)
//                        .padding(.leading)
                    Text(baseItem.overview ?? "")
                        .font(.footnote)
                        .padding()
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
    @Environment(\.seriesViewStrategy) var strategy
    @ObservedObject var node: ItemNode
    
    var body: some View {
        ScrollViewReader { proxy in
            Group {
                switch strategy.scrollDirection {
                case .horizontal:
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 20) {
                            ForEach(node.children, id: \.id) { season in
                                if case .season(_) = season.item {
                                    SeasonView(node: season)
                                        .environmentObject(appState)
                                        .environmentObject(itemRepository)
                                        .environmentObject(drill)
                                        .environment(\.seriesViewStrategy, strategy)
                                        .id(season.uuid)
                                }
                            }
                        }
                    }
                case .vertical:
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(node.children, id: \.id) { season in
                                if case .season(_) = season.item {
                                    SeasonView(node: season)
                                        .environmentObject(appState)
                                        .environmentObject(itemRepository)
                                        .environmentObject(drill)
                                        .environment(\.seriesViewStrategy, strategy)
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
                        if strategy.scrollDirection == .horizontal {
                            proxy.scrollTo(selectedSeason.uuid, anchor: .leading)
                        } else {
                            proxy.scrollTo(selectedSeason.uuid, anchor: .top)
                        }
                    }
                }
                
            }
            .onPreferenceChange(VisibleItemPreferenceKey.self) { values in
                let center = (strategy.scrollDirection == .horizontal) ? UIScreen.main.bounds.midX : UIScreen.main.bounds.midY
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
    
    var body: some View {
        GeometryReader { geometry in
            let strategy = SeriesViewStrategy.resolve(using: geometry)
            VStack(alignment: .leading, spacing: 0) {
                SeriesInfoView(node: node)
                    .environmentObject(appState)
                    .environmentObject(itemRepository)
                    .environmentObject(drill)
                    .frame(height: strategy.infoViewHeight)
                    .background(Color.red)
                    .padding(.leading, 10)
                    .padding(.trailing, 10)
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
                
                RootSeasonView(node: node)
                    .environmentObject(appState)
                    .environmentObject(itemRepository)
                    .environmentObject(drill)
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
