import Foundation
import UIKit

final class ReceiptImageStorage {
    static let shared = ReceiptImageStorage()

    private init() {}

    private var folderURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("ReceiptImages", isDirectory: true)

        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )
        }

        return folder
    }

    func save(_ data: Data) throws -> String {
        guard let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw ReceiptImageError.invalidImage
        }

        let fileName = "\(UUID().uuidString).jpg"
        do {
            try jpegData.write(to: folderURL.appendingPathComponent(fileName), options: .atomic)
        } catch {
            AppStorageIssueReporter.report(.save)
            throw error
        }
        return fileName
    }

    func load(_ fileName: String) -> UIImage? {
        UIImage(contentsOfFile: folderURL.appendingPathComponent(fileName).path)
    }

    func data(for fileName: String) throws -> Data {
        try Data(contentsOf: folderURL.appendingPathComponent(fileName))
    }

    func restore(_ data: Data, fileName: String) throws {
        guard UIImage(data: data) != nil else {
            throw ReceiptImageError.invalidImage
        }

        do {
            try data.write(
                to: folderURL.appendingPathComponent(fileName),
                options: .atomic
            )
        } catch {
            AppStorageIssueReporter.report(.save)
            throw error
        }
    }

    func allFileNames() -> [String] {
        (try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil
        ))?.map(\.lastPathComponent) ?? []
    }

    func delete(_ fileName: String) {
        let url = folderURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            AppStorageIssueReporter.report(.delete)
        }
    }

    func delete(_ fileNames: [String]) {
        fileNames.forEach(delete)
    }
}

enum ReceiptImageError: Error {
    case invalidImage
}
