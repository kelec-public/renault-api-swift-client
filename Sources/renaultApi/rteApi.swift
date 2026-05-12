//
//  File.swift
//
//
//  Created by Kelyan PEGEOT SELME on 09/12/2023.
//

import Foundation

@available(iOS 15.0, *)
@available(watchOS 6.0, *)
@available(macOS 12.0, *)
public struct rteApi {
    private var basicAuth: String
    private var apiUrl = "digital.iservices.rte-france.com"

    public init(basicAuth: String) {
        self.basicAuth = basicAuth

    }

    func getAuthToken() async throws -> AuthReturn? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = self.apiUrl
        components.path = "/token/oauth/"
        var urlRequest = URLRequest(url: URL(string: components.string!)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Basic \(self.basicAuth)", forHTTPHeaderField: "Authorization")
        guard let (data, _) = try? await URLSession.shared.data(for: urlRequest) else {
            throw rteApiError.tokenServerError
        }
        guard let bearerToken = try? JSONDecoder().decode(AuthReturn.self, from: data) else {
            throw rteApiError.tokenDecodeError
        }
        return bearerToken
    }

    func getApiTempoCalendar(bearerToken: String) async throws -> TempoCalendarReturn? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = self.apiUrl
        components.path = "/open_api/tempo_like_supply_contract/v1/tempo_like_calendars"
        var urlRequest = URLRequest(url: URL(string: components.string!)!)
        urlRequest.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, _) = try? await URLSession.shared.data(for: urlRequest) else {
            throw rteApiError.tempoCalendarServerError
        }
        print(String(decoding: data, as: Unicode.UTF8.self))
        guard let tempoCalendar = try? JSONDecoder().decode(TempoCalendarReturn.self, from: data)
        else {
            throw rteApiError.tempoCalendarDecodeError
        }
        return tempoCalendar
    }

    public func getTempo() async throws -> tempoFinalReturn {
        guard let bearerToken = try? await self.getAuthToken() else {
            throw rteApiError.tokenServerError
        }
        guard
            let apiTempoCalendar = try? await self.getApiTempoCalendar(
                bearerToken: bearerToken.access_token)
        else {
            throw rteApiError.tempoCalendarServerError
        }
        let latestValue = apiTempoCalendar.tempo_like_calendars.values[
            apiTempoCalendar.tempo_like_calendars.values.count - 1]
        let latestDate = convertTimestamp(date: latestValue.start_date)

        let currentDate = Date()

        let latestDateStart = Calendar.current.startOfDay(for: latestDate)
        let currentDateStart = Calendar.current.startOfDay(for: currentDate)

        let components = Calendar.current.dateComponents(
            [.day], from: currentDateStart, to: latestDateStart)
        let days = components.day

        var demain = false
        if days == 1 {
            demain = true
        }
        return tempoFinalReturn(tomorrow: demain, colour: latestValue.value, date: latestDate)

    }

    func convertTimestamp(date: String) -> Date {

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZZ"
        return (formatter.date(from: date) ?? Date.now)
    }

    public func getHPPrice(colour: String) -> Float {
        switch colour {
        case "BLUE":
            return 16.12
        case "RED":
            return 70.60
        case "WHITE":
            return 18.71
        default:
            return 0
        }
    }

    public func getHCPrice(colour: String) -> Float {
        switch colour {
        case "BLUE":
            return 13.25
        case "WHITE":
            return 14.99
        case "RED":
            return 15.75
        default:
            return 0
        }
    }

}

public enum rteApiError: Error {
    case tokenServerError
    case tokenDecodeError
    case tempoCalendarServerError
    case tempoCalendarDecodeError
    case tempoCalculationError
}

public struct AuthReturn: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

public struct TempoCalendarReturn: Codable {
    public let tempo_like_calendars: TempoCalendars
}

public struct TempoCalendars: Codable {
    public let start_date: String
    public let end_date: String
    public let values: [TempoCalendarsValue]
}

public struct TempoCalendarsValue: Codable {
    public let start_date: String
    public let end_date: String
    public let value: String
    public let updated_date: String
}

public struct tempoFinalReturn: Codable {
    public let tomorrow: Bool
    public let colour: String
    public let date: Date

    public init(tomorrow: Bool, colour: String, date: Date) {
        self.tomorrow = tomorrow
        self.colour = colour
        self.date = date
    }
}
