//
//  File.swift
//  renaultApi
//
//  Created by Kelyan PEGEOT SELME on 21/01/2025.
//

public typealias Longitude = Double
public typealias Latitude = Double

import Foundation

public protocol ApiClient {
    mutating func setPassword(password: String) -> Void
    func getVehicleInfo(vin: String) async throws -> ApiHandler
    func launchHvac(vin: String) async throws -> Bool
    func getMapCoordinates(vin: String) async throws -> (Latitude, Longitude)
}
