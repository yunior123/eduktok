//
//  StoreKitProView.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 10/12/24.
//

import SwiftUI
import StoreKit
import Foundation
import StoreKit

struct StoreKitProViewMP: View {
    @StateObject private var storeManager = StoreManager()
    
    var body: some View {
        ScrollView {
            if let product = storeManager.product {
                ZStack {
                    // Gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blur(radius: 10)
                    .edgesIgnoringSafeArea(.all) // Covers entire background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white) // White background for the rectangle
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
                            storeManager.purchaseProduct(product)
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
                    image: "exclamationmark.triangle",
                    description: Text("The product you are looking for is currently unavailable.")
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
    
    func fetchProduct() {
        Task {
            do {
                let products = try await Product.products(for: [Products.lifetime])
                DispatchQueue.main.async {
                    print(products)
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
    
    func purchaseProduct(_ product: Product) {
        Task {
            do {
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified:
                        print("Purchase successful and verified!")
                    case .unverified:
                        print("Purchase successful but unverified.")
                    }
                case .userCancelled:
                    print("User cancelled the purchase.")
                case .pending:
                    print("Purchase is pending.")
                @unknown default:
                    print("Unknown error")
                }
            } catch {
                print("Error during purchase: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    StoreKitProViewMP()
}

