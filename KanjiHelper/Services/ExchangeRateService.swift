import Foundation

@MainActor
final class ExchangeRateService {
    static let shared = ExchangeRateService()

    private struct Cache: Codable {
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
    private let cacheKey = "exchangeRateCache"

    private init() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let saved = try? JSONDecoder().decode([String: Cache].self, from: data) else {
            return
        }

        cache = saved.reduce(into: [:]) { result, item in
            guard let currency = AppCurrency(rawValue: item.key) else { return }
            result[currency] = item.value
        }
    }

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

        let staleRates = cache[currency]?.rates

        do {
            return try await fetchRates(for: currency)
        } catch {
            if let staleRates {
                return staleRates
            }
            throw error
        }
    }

    private func fetchRates(for currency: AppCurrency) async throws -> [String: Decimal] {
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
        persistCache()
        return decoded.rates
    }

    private func persistCache() {
        let saved = cache.reduce(into: [String: Cache]()) { result, item in
            result[item.key.rawValue] = item.value
        }

        guard let data = try? JSONEncoder().encode(saved) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }
}

enum ExchangeRateError: Error {
    case invalidURL
    case invalidResponse
    case rateUnavailable
}
