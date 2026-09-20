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
        saveProfiles()
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

    func renameActiveProfile(to name: String) {
        guard let activeProfileId,
              let index = profiles.firstIndex(where: { $0.id == activeProfileId }) else {
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        var profile = profiles[index]
        profile.name = trimmedName
        profiles[index] = profile

        saveProfiles()

        UserDefaults.standard.set(
            trimmedName,
            forKey: "userName"
        )
    }

    func setActiveLanguage(_ language: AppLanguage) {
        updateActiveProfile {
            $0.language = language
        }
    }

    func setActiveHomeCurrency(_ currency: AppCurrency) {
        updateActiveProfile {
            $0.homeCurrency = currency
        }
    }

    func setActiveReferenceCurrency(_ currency: AppCurrency) {
        updateActiveProfile {
            $0.referenceCurrency = currency
        }
    }

    func updateActivePreferences(
        language: AppLanguage,
        homeCurrency: AppCurrency,
        referenceCurrency: AppCurrency
    ) {
        updateActiveProfile {
            $0.language = language
            $0.homeCurrency = homeCurrency
            $0.referenceCurrency = referenceCurrency
        }
    }

    func deleteActiveProfile() {
        guard let activeProfileId else { return }
        deleteProfile(id: activeProfileId)
    }

    func deleteProfile(id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else {
            return
        }

        deleteProfileData(for: id)

        profiles.removeAll { $0.id == id }

        if activeProfileId == id {
            activeProfileId = nil

            UserDefaults.standard.removeObject(
                forKey: activeProfileKey
            )

            UserDefaults.standard.removeObject(
                forKey: "userName"
            )
        }

        saveProfiles()
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

    private func updateActiveProfile(
        _ update: (inout LocalProfile) -> Void
    ) {
        guard let activeProfileId,
              let index = profiles.firstIndex(where: { $0.id == activeProfileId }) else {
            return
        }

        var profile = profiles[index]
        update(&profile)
        profiles[index] = profile
        saveProfiles()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode(
                [LocalProfile].self,
                from: data
           ) {
            profiles = decoded
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

    private func saveProfiles() {
        guard let data = try? JSONEncoder().encode(profiles) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: profilesKey
        )
    }
}
