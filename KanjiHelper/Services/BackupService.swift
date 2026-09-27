import Foundation
import UIKit

struct AppBackupArchive: Codable {
    struct ProfileEvents: Codable {
        let profileId: UUID
        let events: [Event]
    }

    let formatVersion: Int
    let createdAt: Date
    let activeProfileId: UUID?
    let profiles: [LocalProfile]
    let profileEvents: [ProfileEvents]
    let receiptImages: [String: Data]
    let lifecycleStates: [String: EventLifecycleState]
}

enum BackupError: Error {
    case unsupportedVersion
    case invalidArchive
    case missingReceiptImage
    case storageFailure
}

@MainActor
final class BackupService {
    static let shared = BackupService()

    private let formatVersion = 1
    private let fileManager = FileManager.default
    private let receiptStorage = ReceiptImageStorage.shared

    private init() {}

    func export(
        profiles: [LocalProfile],
        activeProfileId: UUID?
    ) throws -> Data {
        let profileEvents = try profiles.map { profile in
            AppBackupArchive.ProfileEvents(
                profileId: profile.id,
                events: try loadEvents(for: profile.id)
            )
        }
        let events = profileEvents.flatMap(\.events)
        let receiptFileNames = Set(
            events.flatMap { event in
                event.expenses.flatMap(\.receiptImages)
            }
        )
        let receiptImages = try Dictionary(
            uniqueKeysWithValues: receiptFileNames.map { fileName in
                guard isSafeReceiptFileName(fileName) else {
                    throw BackupError.invalidArchive
                }
                return (fileName, try receiptStorage.data(for: fileName))
            }
        )
        let eventIds = Set(events.map { $0.id.uuidString })
        let lifecycleStates = EventLifecycleStore.shared.snapshot.filter {
            eventIds.contains($0.key)
        }
        let archive = AppBackupArchive(
            formatVersion: formatVersion,
            createdAt: Date(),
            activeProfileId: activeProfileId,
            profiles: profiles,
            profileEvents: profileEvents,
            receiptImages: receiptImages,
            lifecycleStates: lifecycleStates
        )

        return try encoder.encode(archive)
    }

    func decode(_ data: Data) throws -> AppBackupArchive {
        let archive = try decoder.decode(AppBackupArchive.self, from: data)
        try validate(archive)
        return archive
    }

    func restore(
        _ archive: AppBackupArchive,
        replacing currentProfiles: [LocalProfile]
    ) throws {
        try validate(archive)

        for item in archive.profileEvents {
            let data = try encoder.encode(item.events)
            try data.write(to: eventsURL(for: item.profileId), options: .atomic)
        }

        for (fileName, data) in archive.receiptImages {
            try receiptStorage.restore(data, fileName: fileName)
        }

        let restoredProfileIds = Set(archive.profiles.map(\.id))
        for profile in currentProfiles where !restoredProfileIds.contains(profile.id) {
            try? fileManager.removeItem(at: eventsURL(for: profile.id))
        }

        let restoredReceiptFiles = Set(archive.receiptImages.keys)
        for fileName in receiptStorage.allFileNames() where !restoredReceiptFiles.contains(fileName) {
            receiptStorage.delete(fileName)
        }
    }

    private func loadEvents(for profileId: UUID) throws -> [Event] {
        let url = eventsURL(for: profileId)
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        return try decoder.decode([Event].self, from: Data(contentsOf: url))
    }

    private func validate(_ archive: AppBackupArchive) throws {
        guard archive.formatVersion == formatVersion else {
            throw BackupError.unsupportedVersion
        }
        guard !archive.profiles.isEmpty, archive.profiles.count <= 3 else {
            throw BackupError.invalidArchive
        }

        let profileIds = archive.profiles.map(\.id)
        guard Set(profileIds).count == profileIds.count,
              archive.profiles.allSatisfy({
                  !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              }),
              archive.profileEvents.count == archive.profiles.count,
              Set(archive.profileEvents.map(\.profileId)) == Set(profileIds) else {
            throw BackupError.invalidArchive
        }

        if let activeProfileId = archive.activeProfileId,
           !profileIds.contains(activeProfileId) {
            throw BackupError.invalidArchive
        }

        let events = archive.profileEvents.flatMap(\.events)
        let eventIds = events.map(\.id)
        guard Set(eventIds).count == eventIds.count else {
            throw BackupError.invalidArchive
        }

        let receiptFileNames = Set(
            events.flatMap { event in
                event.expenses.flatMap(\.receiptImages)
            }
        )
        guard receiptFileNames.allSatisfy(isSafeReceiptFileName),
              receiptFileNames == Set(archive.receiptImages.keys),
              archive.receiptImages.values.allSatisfy({ UIImage(data: $0) != nil }) else {
            throw BackupError.missingReceiptImage
        }

        let eventIdStrings = Set(eventIds.map(\.uuidString))
        guard archive.lifecycleStates.keys.allSatisfy(eventIdStrings.contains) else {
            throw BackupError.invalidArchive
        }
    }

    private func isSafeReceiptFileName(_ fileName: String) -> Bool {
        let name = fileName as NSString
        return name.lastPathComponent == fileName &&
            name.pathExtension.lowercased() == "jpg" &&
            UUID(uuidString: name.deletingPathExtension) != nil
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func eventsURL(for profileId: UUID) -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("events-\(profileId.uuidString).json")
    }
}
