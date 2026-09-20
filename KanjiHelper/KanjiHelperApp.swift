import SwiftUI

@main
struct KanjiHelperApp: App {
    @StateObject private var profileStore: ProfileStore
    @StateObject private var eventViewModel: EventViewModel

    init() {
        let profiles = ProfileStore()
        let events = EventViewModel()

        if let profile = profiles.activeProfile {
            events.switchProfile(to: profile.id)
        }

        _profileStore = StateObject(wrappedValue: profiles)
        _eventViewModel = StateObject(wrappedValue: events)
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(profileStore)
                .environmentObject(eventViewModel)
        }
    }
}

private struct AppRootView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var eventViewModel: EventViewModel

    var body: some View {
        Group {
            if profileStore.activeProfile != nil {
                HomeView()
            } else if profileStore.profiles.isEmpty {
                WelcomeView()
            } else {
                ProfileSelectionView()
            }
        }
        .onChange(of: profileStore.activeProfileId) {
            syncActiveProfile()
        }
    }

    private func syncActiveProfile() {
        if let profileId = profileStore.activeProfileId {
            eventViewModel.switchProfile(to: profileId)
        } else {
            eventViewModel.unloadProfile()
        }
    }
}
