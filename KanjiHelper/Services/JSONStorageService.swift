import Foundation

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

    func save<T: Encodable>(_ value: T, filename: String) {
        do {
            let data = try encoder.encode(value)
            try data.write(to: fileURL(for: filename), options: .atomic)
        } catch {
            print("保存エラー: \(error)")
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
            print("読み込みエラー: \(error)")
            return nil
        }
    }

    func delete(filename: String) {
        let url = fileURL(for: filename)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("削除エラー: \(error)")
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
