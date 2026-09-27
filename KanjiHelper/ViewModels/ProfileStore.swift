import SwiftUI
import Combine

@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var profiles: [LocalProfile] = []
    @Published private(set) var activeProfileId: UUID?

    private let storage = JSONStorageService.shared
    private let profilesKey = "localProfiles"
    private let activeProfileKey = "activeProfileId"

    let maximumProfileCount = 3

    init() {
        load()
    }

    var activeProfile: LocalProfile? {
        guard let activeProfileId else { return nil }
        return profiles.first { $0.id == activeProfileId }
    }

    var canCreateProfile: Bool {
        profiles.count < maximumProfileCount
    }

    var activeLanguage: AppLanguage {
        activeProfile?.language ?? .deviceDefault
    }

    var activeHomeCurrency: AppCurrency {
        activeProfile?.homeCurrency
            ?? AppCurrency.deviceDefault(for: activeLanguage)
    }

    var activeReferenceCurrency: AppCurrency {
        activeProfile?.referenceCurrency ?? activeHomeCurrency
    }

    var appName: String {
        activeLanguage.appName
    }

    var appTagline: String {
        activeLanguage.tagline
    }

    @discardableResult
    func createProfile(
        name: String,
        language: AppLanguage? = nil,
        homeCurrency: AppCurrency? = nil,
        referenceCurrency: AppCurrency? = nil
    ) -> LocalProfile? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, canCreateProfile else {
            return nil
        }

        let selectedLanguage = language ?? .deviceDefault
        let selectedHomeCurrency = homeCurrency
            ?? AppCurrency.deviceDefault(for: selectedLanguage)

        let profile = LocalProfile(
            name: trimmedName,
            language: selectedLanguage,
            homeCurrency: selectedHomeCurrency,
            referenceCurrency: referenceCurrency ?? selectedHomeCurrency
        )

        profiles.append(profile)
        guard saveProfiles() else {
            profiles.removeLast()
            return nil
        }
        switchProfile(to: profile.id)

        return profile
    }

    func switchProfile(to id: UUID) {
        guard let profile = profiles.first(where: { $0.id == id }) else {
            return
        }

        activeProfileId = profile.id

        UserDefaults.standard.set(
            profile.id.uuidString,
            forKey: activeProfileKey
        )

        UserDefaults.standard.set(
            profile.name,
            forKey: "userName"
        )
    }

    func leaveCurrentProfile() {
        activeProfileId = nil

        UserDefaults.standard.removeObject(
            forKey: activeProfileKey
        )

        UserDefaults.standard.removeObject(
            forKey: "userName"
        )
    }

    @discardableResult
    func updateActiveSettings(
        name: String,
        language: AppLanguage,
        homeCurrency: AppCurrency,
        referenceCurrency: AppCurrency
    ) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        guard updateActiveProfile({ profile in
            profile.name = trimmedName
            profile.language = language
            profile.homeCurrency = homeCurrency
            profile.referenceCurrency = referenceCurrency
        }) else { return false }

        UserDefaults.standard.set(trimmedName, forKey: "userName")
        return true
    }

    @discardableResult
    func deleteActiveProfile() -> Bool {
        guard let activeProfileId else { return false }
        return deleteProfile(id: activeProfileId)
    }

    @discardableResult
    func deleteProfile(id: UUID) -> Bool {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else {
            return false
        }

        let previousProfiles = profiles
        let previousActiveProfileId = activeProfileId
        profiles.remove(at: index)

        if activeProfileId == id {
            activeProfileId = nil
        }

        guard saveProfiles() else {
            profiles = previousProfiles
            activeProfileId = previousActiveProfileId
            return false
        }

        deleteProfileData(for: id)

        if previousActiveProfileId == id {
            UserDefaults.standard.removeObject(
                forKey: activeProfileKey
            )

            UserDefaults.standard.removeObject(
                forKey: "userName"
            )
        }
        return true
    }

    func exportBackupData() throws -> Data {
        try BackupService.shared.export(
            profiles: profiles,
            activeProfileId: activeProfileId
        )
    }

    func restoreBackupData(_ data: Data) throws {
        let archive = try BackupService.shared.decode(data)
        try BackupService.shared.restore(archive, replacing: profiles)

        profiles = archive.profiles
        activeProfileId = archive.activeProfileId ?? archive.profiles.first?.id
        guard saveProfiles() else { throw BackupError.storageFailure }
        EventLifecycleStore.shared.replace(with: archive.lifecycleStates)

        if let profile = activeProfile {
            UserDefaults.standard.set(profile.id.uuidString, forKey: activeProfileKey)
            UserDefaults.standard.set(profile.name, forKey: "userName")
        } else {
            UserDefaults.standard.removeObject(forKey: activeProfileKey)
            UserDefaults.standard.removeObject(forKey: "userName")
        }
    }

    private func deleteProfileData(for id: UUID) {
        let filename = "events-\(id.uuidString).json"

        if let events = storage.load(
            [Event].self,
            filename: filename
        ) {
            let receiptFiles = events.flatMap { event in
                event.expenses.flatMap { $0.receiptImages }
            }

            ReceiptImageStorage.shared.delete(receiptFiles)

            for event in events {
                EventLifecycleStore.shared.removeState(for: event.id)
            }
        }

        storage.delete(filename: filename)
    }

    @discardableResult
    private func updateActiveProfile(
        _ update: (inout LocalProfile) -> Void
    ) -> Bool {
        guard let activeProfileId,
              let index = profiles.firstIndex(where: { $0.id == activeProfileId }) else {
            return false
        }

        let previousProfile = profiles[index]
        update(&profiles[index])

        guard saveProfiles() else {
            profiles[index] = previousProfile
            return false
        }
        return true
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: profilesKey) {
            do {
                profiles = try JSONDecoder().decode([LocalProfile].self, from: data)
            } catch {
                AppStorageIssueReporter.report(.load)
            }
        }

        if let idString = UserDefaults.standard.string(forKey: activeProfileKey),
           let id = UUID(uuidString: idString),
           profiles.contains(where: { $0.id == id }) {
            activeProfileId = id

            if let profile = activeProfile {
                UserDefaults.standard.set(
                    profile.name,
                    forKey: "userName"
                )
            }
        }
    }

    @discardableResult
    private func saveProfiles() -> Bool {
        let data: Data

        do {
            data = try JSONEncoder().encode(profiles)
        } catch {
            AppStorageIssueReporter.report(.save)
            return false
        }

        UserDefaults.standard.set(
            data,
            forKey: profilesKey
        )
        return true
    }
}
