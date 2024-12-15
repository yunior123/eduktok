//
//  struct.swift
//  eduktok
//
//  Created by Yunior Rodriguez Osorio on 13/12/24.
//

import Foundation


// Define the PurchaseRecord struct
struct PurchaseRecord: Codable {
    let userDocId: String
    let appAccountToken: UUID
    let productId: String
    let date: Date
    let transactionId: String
}
