import Foundation

@MainActor
final class ExchangeRateService {
    static let shared = ExchangeRateService()

    private struct Cache {
        let rates: [String: Decimal]
        let expiresAt: Date
    }

    private struct Response: Decodable {
        let result: String
        let rates: [String: Decimal]
        let timeNextUpdateUnix: TimeInterval

        enum CodingKeys: String, CodingKey {
            case result, rates
            case timeNextUpdateUnix = "time_next_update_unix"
        }
    }

    private var cache: [AppCurrency: Cache] = [:]

    private init() {}

    func convert(minorUnits: Int, from: AppCurrency, to: AppCurrency) async throws -> Int {
        guard from != to else { return minorUnits }

        let conversionRate = try await rate(from: from, to: to)
        let sourceAmount = Decimal(minorUnits) / Decimal(from.minorUnitScale)

        var scaled = sourceAmount * conversionRate * Decimal(to.minorUnitScale)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)

        return NSDecimalNumber(decimal: rounded).intValue
    }

    func rate(from: AppCurrency, to: AppCurrency) async throws -> Decimal {
        guard from != to else { return 1 }

        let rates = try await rates(for: from)

        guard let rate = rates[to.code] else {
            throw ExchangeRateError.rateUnavailable
        }

        return rate
    }

    private func rates(for currency: AppCurrency) async throws -> [String: Decimal] {
        if let cached = cache[currency], cached.expiresAt > Date() {
            return cached.rates
        }

        guard let url = URL(string: "https://open.er-api.com/v6/latest/\(currency.code)") else {
            throw ExchangeRateError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw ExchangeRateError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)

        guard decoded.result == "success" else {
            throw ExchangeRateError.invalidResponse
        }

        let nextUpdate = Date(timeIntervalSince1970: decoded.timeNextUpdateUnix)
        let expiresAt = nextUpdate > Date()
            ? nextUpdate
            : Date().addingTimeInterval(60 * 60 * 24)

        cache[currency] = Cache(rates: decoded.rates, expiresAt: expiresAt)
        return decoded.rates
    }
}

enum ExchangeRateError: Error {
    case invalidURL
    case invalidResponse
    case rateUnavailable
}
