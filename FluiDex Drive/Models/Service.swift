//
//  Service.swift
//  FluiDex Drive
//
//  Created by Irina Saf on 2025-09-26.
//


import Foundation

struct Service: Identifiable {
    let id = UUID()
    let type: String
    let date: Date
    let mileage: Int
    let cost: Double
}
