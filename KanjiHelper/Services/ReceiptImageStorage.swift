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
        try jpegData.write(to: folderURL.appendingPathComponent(fileName), options: .atomic)
        return fileName
    }

    func load(_ fileName: String) -> UIImage? {
        UIImage(contentsOfFile: folderURL.appendingPathComponent(fileName).path)
    }

    func delete(_ fileName: String) {
        try? FileManager.default.removeItem(at: folderURL.appendingPathComponent(fileName))
    }

    func delete(_ fileNames: [String]) {
        fileNames.forEach(delete)
    }
}

enum ReceiptImageError: Error {
    case invalidImage
}
