//
//  StatisticsChart.swift
//  Wikist
//
//  Created by Lucka on 28/11/2022.
//

import SwiftUI

struct StatisticsChart<Builder: StatisticsChartBuilder>: View {
    
    @State private var isSheetPresented = false
    
    private let briefData: Builder.BriefData
    private let builder = Builder()
    private let user: User
    
    init(user: User, briefData: Builder.BriefData) {
        self.user = user
        self.briefData = briefData
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(builder.briefTitleKey, systemImage: builder.briefSystemImage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .labelStyle(.monospacedIconAndTitle)
            Spacer(minLength: 4)
            builder.makeBriefChart(data: briefData)
        }
        .card()
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            isSheetPresented.toggle()
        }
        .sheet(isPresented: $isSheetPresented) {
            NavigationStack {
                builder.makeChart(user: user)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            ThemedButton.dismiss {
                                isSheetPresented.toggle()
                            }
                        }
                    }
#if os(macOS)
                    .frame(minWidth: 320, minHeight: 320)
#else
                    .navigationBarTitleDisplayMode(.inline)
#endif
            }
        }
    }
}

protocol StatisticsChartBuilder {
    associatedtype BriefData
    associatedtype BriefChartContent: View
    associatedtype ChartContent: View
    
    var briefTitleKey: LocalizedStringKey { get }
    var briefSystemImage: String { get }
    
    init()
    
    @ViewBuilder
    func makeBriefChart(data: BriefData) -> BriefChartContent
    
    @ViewBuilder
    func makeChart(user: User) -> ChartContent
}
