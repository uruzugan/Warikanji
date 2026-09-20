import SwiftUI

struct ProfileSelectionView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var showCreateProfile = false
    @State private var newName = ""

    private var language: AppLanguage { profileStore.activeLanguage }
    private var remainingCount: Int {
        profileStore.maximumProfileCount - profileStore.profiles.count
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    brandHeader

                    VStack(alignment: .leading, spacing: 14) {
                        Text(language.profileText(.selectAccount))
                            .font(.title2.bold())

                        Text(language.profileText(.selectDescription))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 12) {
                        ForEach(profileStore.profiles) { profile in
                            Button {
                                profileStore.switchProfile(to: profile.id)
                            } label: {
                                profileRow(profile)
                            }
                            .buttonStyle(.plain)
                        }

                        if profileStore.canCreateProfile {
                            addAccountButton
                        }
                    }

                    Text(language.profileText(.localOnly))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .padding(.top, 22)
            }
        }
        .sheet(isPresented: $showCreateProfile) {
            createProfileSheet
        }
    }

    private var brandHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 82, height: 82)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 22))

            Text(language.appName)
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text(language.tagline)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
        }
    }

    private func profileRow(_ profile: LocalProfile) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "person.fill")
                .foregroundStyle(AppTheme.primary)
                .frame(width: 46, height: 46)
                .background(AppTheme.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name).font(.headline)

                Text(language.profileText(.continueAccount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .appCard()
    }

    private var addAccountButton: some View {
        Button {
            newName = ""
            showCreateProfile = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.badge.plus")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 46, height: 46)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(language.profileText(.addAccount)).font(.headline)

                    Text(language.remainingProfiles(remainingCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(AppTheme.primary)
            }
            .appCard()
        }
        .buttonStyle(.plain)
    }

    private var createProfileSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(language.profileText(.displayName), text: $newName)
                } header: {
                    Text(language.profileText(.newAccount))
                } footer: {
                    Text(language.profileText(.separateData))
                }
            }
            .navigationTitle(language.profileText(.createAccount))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.profileText(.cancel)) {
                        showCreateProfile = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(language.profileText(.create)) {
                        profileStore.createProfile(name: newName)
                        showCreateProfile = false
                    }
                    .disabled(
                        newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
    }
}

#Preview {
    ProfileSelectionView()
        .environmentObject(ProfileStore())
}
