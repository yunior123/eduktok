//
//  StoreKitProView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 10/12/24.
//

import Foundation
import StoreKit
import SwiftUI

struct StoreKitProViewMP: View {
    @StateObject private var storeManager = StoreManager()
    let userDocId: String

    var body: some View {
        ScrollView {
            if let product = storeManager.product {
                ZStack {
                    // Gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.8), Color.purple.opacity(0.8),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blur(radius: 10)
                    .edgesIgnoringSafeArea(.all)  // Covers entire background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)  // White background for the rectangle
                        .shadow(radius: 8)
                        .padding()

                    VStack(spacing: 16) {
                        Image("artwork")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300, maxHeight: 300)
                            .cornerRadius(12)

                        Text(product.displayName)
                            .font(.title)
                            .bold()
                            .foregroundColor(.blue)

                        Text(product.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)

                        Button(action: {
                            storeManager.purchaseProduct(product, userDocId)
                        }) {
                            Text("Buy for \(product.displayPrice)")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(2)
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "Product unavailable",
                    systemImage: "cart",
                    description: Text(
                        "The product you are looking for is currently unavailable."
                    )
                )
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
                            transactionId: String(transaction.id)
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
                        #warning(
                            "Mark transactions as finish after granting user access to their purchase"
                        )
                        await transaction.finish()  // Mark transaction as complete
                    case .unverified(_, let error):
                        print(
                            "Purchase successful but unverified: \(error.localizedDescription)"
                        )
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
}

#Preview {
    StoreKitProViewMP(userDocId: "userDocId")
}
