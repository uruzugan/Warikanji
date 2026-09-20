import Foundation

enum ShareRoundingCalculator {
    static func round(
        theoretical: [UUID: Double],
        total: Int,
        unit: Int,
        order: [UUID]
    ) -> [UUID: Int] {
        guard unit > 1 else {
            return exact(
                theoretical: theoretical,
                total: total,
                order: order
            )
        }

        var result: [UUID: Int] = [:]

        for id in order {
            let value = max(theoretical[id] ?? 0, 0)
            result[id] = Int((value / Double(unit)).rounded()) * unit
        }

        var difference = total - result.values.reduce(0, +)

        while abs(difference) >= unit {
            let adjustment = difference > 0 ? unit : -unit

            guard let id = bestCandidate(
                theoretical: theoretical,
                result: result,
                adjustment: adjustment,
                order: order
            ) else { break }

            result[id, default: 0] += adjustment
            difference -= adjustment
        }

        if difference != 0 {
            let candidates = order.filter {
                result[$0, default: 0] + difference >= 0
            }

            if let id = candidates.min(by: {
                error(
                    id: $0,
                    adjustment: difference,
                    theoretical: theoretical,
                    result: result
                ) < error(
                    id: $1,
                    adjustment: difference,
                    theoretical: theoretical,
                    result: result
                )
            }) {
                result[id, default: 0] += difference
            }
        }

        return result
    }

    static func exact(
        theoretical: [UUID: Double],
        total: Int,
        order: [UUID]
    ) -> [UUID: Int] {
        var result: [UUID: Int] = [:]
        var fractions: [(UUID, Double)] = []

        for id in order {
            let value = max(theoretical[id] ?? 0, 0)
            let base = Int(floor(value))
            result[id] = base
            fractions.append((id, value - Double(base)))
        }

        var remainder = total - result.values.reduce(0, +)

        fractions.sort {
            if $0.1 == $1.1 {
                return index(of: $0.0, in: order) <
                    index(of: $1.0, in: order)
            }

            return $0.1 > $1.1
        }

        var index = 0

        while remainder > 0 && !fractions.isEmpty {
            result[fractions[index % fractions.count].0, default: 0] += 1
            remainder -= 1
            index += 1
        }

        return result
    }

    private static func bestCandidate(
        theoretical: [UUID: Double],
        result: [UUID: Int],
        adjustment: Int,
        order: [UUID]
    ) -> UUID? {
        order
            .filter {
                result[$0, default: 0] + adjustment >= 0
            }
            .min {
                error(
                    id: $0,
                    adjustment: adjustment,
                    theoretical: theoretical,
                    result: result
                ) < error(
                    id: $1,
                    adjustment: adjustment,
                    theoretical: theoretical,
                    result: result
                )
            }
    }

    private static func error(
        id: UUID,
        adjustment: Int,
        theoretical: [UUID: Double],
        result: [UUID: Int]
    ) -> Double {
        let target = theoretical[id] ?? 0
        let current = Double(result[id, default: 0])
        let adjusted = current + Double(adjustment)

        return abs(adjusted - target) - abs(current - target)
    }

    private static func index(
        of id: UUID,
        in order: [UUID]
    ) -> Int {
        order.firstIndex(of: id) ?? Int.max
    }
}
