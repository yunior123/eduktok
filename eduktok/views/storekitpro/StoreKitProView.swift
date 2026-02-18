//
//  StoreKitProView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 10/12/24.
//

import Foundation
import StoreKit
import SwiftUI
import FirebaseAuth

struct StoreKitProViewMP: View {
    @StateObject private var storeManager = StoreManager()
    let userDocId: String

    var body: some View {
        ZStack {
            OrignaLBackdrop()
            ScrollView {
                VStack(spacing: 16) {
                    Image("artwork")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 320, maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(OrignaLTheme.ice.opacity(0.25), lineWidth: 1)
                        )

                    Text(storeManager.product?.displayName ?? "Lifetime")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(OrignaLTheme.ice)
                        .accessibilityIdentifier("store.title")

                    Text(storeManager.product?.description ?? "Unlock every unit and lesson forever.")
                        .font(.body.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(OrignaLTheme.ice.opacity(0.88))
                        .accessibilityIdentifier("store.description")

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Unlimited access to all 50 units", systemImage: "checkmark.seal.fill")
                        Label("All phrase images and lesson audio", systemImage: "waveform.circle.fill")
                        Label("No monthly fee. Pay once.", systemImage: "crown.fill")
                    }
                    .foregroundStyle(OrignaLTheme.ice)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        if let product = storeManager.product {
                            storeManager.purchaseProduct(product, userDocId)
                        }
                    }) {
                        Text("Buy for \(storeManager.product?.displayPrice ?? "$17.99")")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(OrignaLTheme.buttonGradient)
                            .foregroundStyle(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .accessibilityIdentifier("store.buyButton")

                    #if DEBUG
                    if UITestLaunchFlags.usesRealDatabaseFlow {
                        Button("Test Activate Lifetime") {
                            Task {
                                await storeManager.activateLifetimeForUITest(userDocId: userDocId)
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.white.opacity(0.14))
                        .foregroundStyle(OrignaLTheme.ice)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .accessibilityIdentifier("store.testLifetimeButton")
                    }
                    #endif
                }
                .padding(18)
                .orignalGlassCard()
                .padding(16)
            }
        }
        .onAppear {
            storeManager.fetchProduct()
        }
    }
}

class StoreManager: ObservableObject {
    @Published var product: Product?
    @Published var hasLifetimeAccess: Bool = false  // State for lifetime access

    func fetchProduct() {
        Task { [weak self] in
            guard let self = self else { return }  // Safely unwrap `self`

            do {
                let products = try await Product.products(for: [
                    Products.lifetime
                ])
                await MainActor.run {
                    if let fetchedProduct = products.first {
                        self.product = fetchedProduct
                    } else {
                        print("Product not found.")
                    }
                }
            } catch {
                print("Error fetching product: \(error.localizedDescription)")
            }
        }
    }
    //  You create an appAccountToken(_:) and send it to the App Store when a customer initiates an in-app purchase. The App Store returns the same value in appAccountToken in the transaction information after the customer completes the purchase.
    func purchaseProduct(_ product: Product, _ userDocId: String) {
        Task {
            do {
                let appAccountToken = UUID()

                let purchaseResult = try await product.purchase(options: [
                    .appAccountToken(appAccountToken)
                ])


                switch purchaseResult {
                case .success(let verification):
                    switch verification {
                    case .verified(let transaction):
                        print("Purchase successful and verified!")
                        let transactionRecord = PurchaseRecord(
                            userDocId: userDocId,
                            appAccountToken: appAccountToken,
                            productId: product.id,
                            date: Date(),
                            transactionId: String(transaction.id),
                            environment: transaction.environment.rawValue
                        )
                        // Save the purchase record to Firestore
                        do {
                            let db = Db()
                            print(transactionRecord)
                            let recordID = try await db.createPurchaseRecord(
                                transactionRecord)
                            print("Purchase record saved with ID: \(recordID)")

                            // Grant access to content
                            await self.grantAccessToContent()
                            print("Access granted to content.")
                        } catch {
                            #warning("Send to Crashlytics")
                            print(
                                "Failed to save purchase record or grant access: \(error.localizedDescription)"
                            )
                        }
                        await transaction.finish()
                    case .unverified(let transaction, let error):
                        print(
                            "Purchase successful but unverified: \(error.localizedDescription)"
                        )
                        await transaction.finish()
                    }
                case .userCancelled:
                    print("User cancelled the purchase.")
                case .pending:
                    print("Purchase is pending.")
                @unknown default:
                    print("Unknown error occurred.")
                }
            } catch {
                print("Error during purchase: \(error.localizedDescription)")
            }
        }
    }

    /// Grants lifetime access for the moment by updating the app state
    /// The real content access granting happens on the server side
    /// once the transaction is validated
    func grantAccessToContent() async {
        await MainActor.run { [weak self] in
            self?.hasLifetimeAccess = true
        }
    }

    func activateLifetimeForUITest(userDocId: String) async {
        do {
            let db = Db()
            if let email = Auth.auth().currentUser?.email,
               let user = try await db.findUser(email: email) {
                try await db.updateUser(user: user.copyWith(hasLifetimeAccess: true))
            }

            let transactionRecord = PurchaseRecord(
                userDocId: userDocId,
                appAccountToken: UUID(),
                productId: Products.lifetime,
                date: Date(),
                transactionId: "ui-test-\(UUID().uuidString)",
                environment: "ui-test"
            )
            _ = try await db.createPurchaseRecord(transactionRecord)
            await grantAccessToContent()
        } catch {
            print("UITest lifetime activation failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    StoreKitProViewMP(userDocId: "userDocId")
}

#warning("implement this")
//func restorePurchases() {
//    SKPaymentQueue.default().restoreCompletedTransactions()
//}
