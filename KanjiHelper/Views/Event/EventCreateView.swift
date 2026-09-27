import SwiftUI

struct EventCreateView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var eventType: EventType = .drinkingParty
    @State private var date = Date()
    @State private var endDate = Date().addingTimeInterval(60 * 60 * 2)
    @State private var location = ""
    @State private var memo = ""
    @State private var participantCount = 1
    @State private var currency: AppCurrency = .jpy
    @State private var hasLoadedDefaults = false

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    EventCreateHero(
                        title: title,
                        eventType: eventType,
                        date: date,
                        participantCount: participantCount,
                        language: language
                    )

                    EventScheduleInfoCard(
                        title: $title,
                        startDate: $date,
                        endDate: $endDate,
                        location: $location,
                        language: language
                    )

                    EventTypePickerCard(eventType: $eventType, language: language)
                    EventCurrencyCard(currency: $currency, language: language)
                    EventParticipantCountCard(participantCount: $participantCount, language: language)
                    EventMemoCard(memo: $memo, language: language)
                    saveButton
                }
                .padding()
                .padding(.bottom, 8)
            }
            .background(AppTheme.background)
            .navigationTitle(language.eventText(.newEvent))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(language.eventText(.cancel)) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadDefaultsIfNeeded()
            }
        }
        .tint(AppTheme.primary)
    }

    private var saveButton: some View {
        Button(action: save) {
            Label(language.eventText(.createEvent), systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
    }

    private func loadDefaultsIfNeeded() {
        guard !hasLoadedDefaults else { return }
        currency = profileStore.activeHomeCurrency
        hasLoadedDefaults = true
    }

    private func save() {
        let event = Event(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            endDate: endDate,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
            eventType: eventType,
            currency: currency,
            expectedParticipantCount: participantCount
        )

        if viewModel.addEvent(event) {
            dismiss()
        }
    }
}

#Preview {
    EventCreateView()
        .environmentObject(EventViewModel())
        .environmentObject(ProfileStore())
}
