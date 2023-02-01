//
//  AboutSectionContent.swift
//  Wikist
//
//  Created by Lucka on 15/12/2022.
//

import StoreKit
import SwiftUI

struct AboutSection: View {
    
    @State private var isOnboardingSheetPresented = false
    @State private var isTipDialogPresented = false
    @State private var products: [ Product ] = [ ]
    
    var body: some View {
        Section {
            Button {
                isOnboardingSheetPresented = true
            } label: {
                Label("AboutSection.OnBoarding", systemImage: "hand.wave")
#if os(macOS)
                    .labelStyle(.titleOnly)
#endif
            }

#if os(iOS)
            if UIApplication.shared.supportsAlternateIcons {
                NavigationLink {
                    AppIconSelector()
                } label: {
                    Label("AboutSection.ChangeAppIcon", systemImage: "app.dashed")
                }
            }
#endif
            
            if AppStore.canMakePayments {
                Button {
                    isTipDialogPresented.toggle()
                } label: {
                    Label("AboutSection.Tips", systemImage: "app.gift")
#if os(macOS)
                        .labelStyle(.titleOnly)
#endif
                }
            }
            
            Link(destination: .init(string: "https://github.com/lucka-me/wikist-swift")!) {
                Label("AboutSection.SourceCode", systemImage: "swift")
            }
            
            Label(Bundle.main.shortVersionString, systemImage: "app.badge.checkmark")
                .badge(Bundle.main.version)
        } footer: {
            Text("Made by Lucka with \(Image(systemName: "heart.fill"))")
        }
        .sheet(isPresented: $isOnboardingSheetPresented) {
            OnboardingView()
        }
        .confirmationDialog("AboutSection.Tips", isPresented: $isTipDialogPresented) {
            ForEach(products) { product in
                Button("\(product.displayName) - \(product.displayPrice)") {
                    Task {
                        await tryPurchase(product)
                    }
                }
            }
        }
        .task {
            guard AppStore.canMakePayments else { return }
            do {
                let products = try await Product.products(for: TipProduct.allCases.map { $0.rawValue })
                await MainActor.run {
                    self.products = products
                }
            } catch {
                
            }
        }
    }
    
    private func tryPurchase(_ product: Product) async {
        guard
            let result = try? await product.purchase(),
            case let .success(verification) = result,
            case let .verified(transaction) = verification
        else {
            return
        }
        await transaction.finish()
    }
}

#if DEBUG
struct AboutSectionPreviews: PreviewProvider {
    static var previews: some View {
        Form {
            AboutSection()
        }
        .formStyle(.grouped)
    }
}
#endif

fileprivate enum TipProduct: String, CaseIterable {
    case tier1 = "dev.lucka.Wikist.IAP.supportTire1"
    case tier2 = "dev.lucka.Wikist.IAP.supportTire2"
}
