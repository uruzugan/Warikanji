import Foundation

enum AppStorageOperation: String, Identifiable {
    case save
    case load
    case delete

    var id: String { rawValue }
}

extension Notification.Name {
    static let appStorageFailure = Notification.Name("appStorageFailure")
}

enum AppStorageIssueReporter {
    private static let lock = NSLock()
    private static var pendingOperation: AppStorageOperation?

    static func report(_ operation: AppStorageOperation) {
        lock.lock()
        pendingOperation = operation
        lock.unlock()

        let notify = {
            NotificationCenter.default.post(
                name: .appStorageFailure,
                object: operation
            )
        }

        if Thread.isMainThread {
            notify()
        } else {
            DispatchQueue.main.async(execute: notify)
        }
    }

    static func takePendingOperation() -> AppStorageOperation? {
        lock.lock()
        defer {
            pendingOperation = nil
            lock.unlock()
        }
        return pendingOperation
    }
}

final class JSONStorageService {
    static let shared = JSONStorageService()

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    @discardableResult
    func save<T: Encodable>(_ value: T, filename: String) -> Bool {
        do {
            let data = try encoder.encode(value)
            try data.write(to: fileURL(for: filename), options: .atomic)
            return true
        } catch {
            AppStorageIssueReporter.report(.save)
            return false
        }
    }

    func load<T: Decodable>(_ type: T.Type, filename: String) -> T? {
        let url = fileURL(for: filename)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            return try decoder.decode(
                type,
                from: Data(contentsOf: url)
            )
        } catch {
            AppStorageIssueReporter.report(.load)
            return nil
        }
    }

    @discardableResult
    func delete(filename: String) -> Bool {
        let url = fileURL(for: filename)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return true
        }

        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            AppStorageIssueReporter.report(.delete)
            return false
        }
    }

    private func fileURL(for filename: String) -> URL {
        FileManager.default
            .urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            .appendingPathComponent(filename)
    }
}
