//
//  AboutSectionContent.swift
//  Wikist
//
//  Created by Lucka on 15/12/2022.
//

import StoreKit
import SwiftUI

struct AboutSection: View {
    
    @ObservedObject private var tipsManager = TipsManager.shared
    
    @State private var isOnboardingSheetPresented = false
    @State private var isTipDialogPresented = false
    
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
            
            if tipsManager.canMakePayment {
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
            ForEach(tipsManager.products, id: \.productIdentifier) { product in
                Button(product.localizedText) {
                    tipsManager.purchase(product)
                }
            }
        }
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

fileprivate class TipsManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    static let shared = TipsManager()
    
    static let tier1ProductIdentifier = "dev.lucka.Wikist.IAP.supportTire1"
    static let tier2ProductIdentifier = "dev.lucka.Wikist.IAP.supportTire2"
    
    @Published var products: [ SKProduct ] = [ ]
    @Published var purchased = false
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async { [ self ] in
            products = response.products
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [ SKPaymentTransaction ]) {
        DispatchQueue.main.async { [ self ] in
            for transaction in transactions {
                if transaction.transactionState == .purchased {
                    purchased = true
                }
            }
        }
    }
    
    func purchase(_ product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    var canMakePayment: Bool {
        SKPaymentQueue.canMakePayments()
    }
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        if canMakePayment {
            let request = SKProductsRequest(
                productIdentifiers: [ Self.tier1ProductIdentifier, Self.tier2ProductIdentifier ]
            )
            request.delegate = self
            request.start()
        }
    }
}

extension SKProduct {
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? "\(price)"
    }
    
    var localizedText: String {
        "\(localizedTitle) - \(localizedPrice)"
    }
}
