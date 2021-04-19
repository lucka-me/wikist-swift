//
//  TipView.swift
//  macOS
//
//  Created by Lucka on 18/4/2021.
//

import SwiftUI

struct TipView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var support = Support.shared
    @State private var selectedId = ""
    
    var body: some View {
        ScrollView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(support.products, id:\.productIdentifier) { product in
                        CardView.Card {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.localizedTitle)
                                    Text(product.localizedDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(product.localizedPrice)
                                    .font(.system(.title, design: .rounded))
                            }
                        }
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: CardView.defaultRadius)
                                .stroke(
                                    selectedId == product.productIdentifier ? Color.accentColor.opacity(0.5) : Color.clear,
                                    lineWidth: 3
                                )
                        )
                        .padding(3)
                        .animation(.default)
                        .onTapGesture {
                            selectedId = product.productIdentifier
                            support.purchase(product)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 300, minHeight: 200)
        .navigationTitle("view.tip")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("view.action.dismiss") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .alert(isPresented: $support.purchased) {
            .init(
                title: Text("view.tip.thanks"),
                dismissButton: .default(Text("view.action.dismiss")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

#if DEBUG
struct TipView_Previews: PreviewProvider {
    static var previews: some View {
        TipView()
    }
}
#endif
