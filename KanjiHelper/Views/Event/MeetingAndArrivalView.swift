import PhotosUI
import SwiftUI
import UIKit

struct MeetingAndArrivalView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore

    let eventId: UUID

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        Group {
            if let event {
                List {
                    Section {
                        Label(
                            language.planningText(.meetingAndArrivalDescription),
                            systemImage: "location.circle.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Section(language.planningText(.meetingPoint)) {
                        NavigationLink {
                            MeetingPointEditView(eventId: eventId)
                        } label: {
                            meetingPointRow(event.planning.meetingPlan)
                        }
                    }

                    Section(language.planningText(.arrivalSummary)) {
                        arrivalSummary(event)
                    }

                    Section(language.planningText(.participants)) {
                        ForEach(event.participants) { participant in
                            NavigationLink {
                                ArrivalStatusEditView(
                                    eventId: eventId,
                                    participantId: participant.id
                                )
                            } label: {
                                participantRow(participant, event: event)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    language.planningText(.meetingAndArrivalTitle),
                    systemImage: "location.slash"
                )
            }
        }
        .navigationTitle(language.planningText(.meetingAndArrivalTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func meetingPointRow(_ plan: EventMeetingPlan) -> some View {
        HStack(spacing: 12) {
            if let data = plan.photoData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    plan.isConfigured
                        ? plan.name
                        : language.planningText(.noMeetingPoint)
                )
                .font(.body.bold())

                if let meetingAt = plan.meetingAt {
                    Label(
                        meetingAt.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if !plan.instructions.isEmpty {
                    Text(plan.instructions)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 3)
    }

    private func arrivalSummary(_ event: Event) -> some View {
        let counts = Dictionary(
            grouping: event.participants,
            by: { arrivalStatus(for: $0.id, event: event) }
        ).mapValues(\.count)

        return HStack(spacing: 8) {
            ForEach(ArrivalStatus.allCases, id: \.self) { status in
                VStack(spacing: 4) {
                    Text("\(counts[status, default: 0])")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(statusColor(status))
                    Text(status.displayName(for: language))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }

    private func participantRow(
        _ participant: EventParticipant,
        event: Event
    ) -> some View {
        let status = arrivalStatus(for: participant.id, event: event)

        return HStack(spacing: 12) {
            Image(systemName: statusSymbol(status))
                .foregroundStyle(statusColor(status))
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.displayName(for: participant.id, language: language))
                Text(status.displayName(for: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func arrivalStatus(
        for participantId: UUID,
        event: Event
    ) -> ArrivalStatus {
        event.planning.participantResponses.first {
            $0.participantId == participantId
        }?.arrivalStatus ?? .notShared
    }

    private func statusColor(_ status: ArrivalStatus) -> Color {
        switch status {
        case .notShared: return .secondary
        case .onTheWay: return AppTheme.primary
        case .arrived: return AppTheme.success
        case .delayed: return AppTheme.warning
        }
    }

    private func statusSymbol(_ status: ArrivalStatus) -> String {
        switch status {
        case .notShared: return "ellipsis.circle.fill"
        case .onTheWay: return "figure.walk.circle.fill"
        case .arrived: return "checkmark.circle.fill"
        case .delayed: return "clock.badge.exclamationmark.fill"
        }
    }
}

private struct ArrivalStatusEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID
    let participantId: UUID

    @State private var response: ParticipantResponse
    @State private var hasLoaded = false

    init(eventId: UUID, participantId: UUID) {
        self.eventId = eventId
        self.participantId = participantId
        _response = State(
            initialValue: ParticipantResponse(participantId: participantId)
        )
    }

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }

    var body: some View {
        Form {
            Section(language.planningText(.arrivalStatus)) {
                Picker(
                    language.planningText(.arrivalStatus),
                    selection: $response.arrivalStatus
                ) {
                    ForEach(ArrivalStatus.allCases, id: \.self) { status in
                        Text(status.displayName(for: language)).tag(status)
                    }
                }
            }
        }
        .navigationTitle(participantName)
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isLocked)
        .toolbar {
            if !isLocked {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.planningText(.save), action: save)
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    private var participantName: String {
        event?.displayName(for: participantId, language: language)
            ?? language.planningText(.arrivalStatus)
    }

    private func loadIfNeeded() {
        guard !hasLoaded else { return }
        if let saved = event?.planning.participantResponses.first(where: {
            $0.participantId == participantId
        }) {
            response = saved
        }
        hasLoaded = true
    }

    private func save() {
        if viewModel.saveParticipantResponse(response, in: eventId) {
            dismiss()
        }
    }
}

private struct MeetingPointEditView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID

    @State private var plan = EventMeetingPlan()
    @State private var hasMeetingTime = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var hasLoaded = false

    private var event: Event? { viewModel.event(for: eventId) }
    private var language: AppLanguage { profileStore.activeLanguage }
    private var isLocked: Bool { !viewModel.canEdit(eventId) }
    private var isSaveDisabled: Bool { !plan.isConfigured }

    var body: some View {
        Form {
            Section(language.planningText(.meetingPoint)) {
                TextField(
                    language.planningText(.meetingPointName),
                    text: $plan.name
                )
                TextField(
                    language.planningText(.meetingInstructions),
                    text: $plan.instructions,
                    axis: .vertical
                )
                .lineLimit(2...6)

                Toggle(
                    language.planningText(.meetingTime),
                    isOn: $hasMeetingTime
                )
                if hasMeetingTime {
                    DatePicker(
                        language.planningText(.meetingTime),
                        selection: meetingTimeBinding,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }

            Section(language.planningText(.meetingPhoto)) {
                if let data = plan.photoData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button(
                        language.planningText(.removePhoto),
                        role: .destructive
                    ) {
                        plan.photoData = nil
                    }
                } else {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(
                            language.planningText(.choosePhoto),
                            systemImage: "photo.on.rectangle"
                        )
                    }

                    Button {
                        openCamera()
                    } label: {
                        Label(
                            language.planningText(.takePhoto),
                            systemImage: "camera.fill"
                        )
                    }
                }
            }
        }
        .navigationTitle(language.planningText(.editMeetingPoint))
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isLocked)
        .toolbar {
            if !isLocked {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.planningText(.save), action: save)
                        .disabled(isSaveDisabled)
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
        .onChange(of: pickerItem) { _, item in loadPhoto(item) }
        .onChange(of: hasMeetingTime) { _, enabled in
            if enabled, plan.meetingAt == nil {
                plan.meetingAt = event?.date ?? Date()
            } else if !enabled {
                plan.meetingAt = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker { image in
                plan.photoData = compressedPhoto(from: image)
            }
            .ignoresSafeArea()
        }
        .alert(
            language.text(
                ja: "カメラを使用できません", en: "Camera Unavailable",
                zhHans: "无法使用相机", zhHant: "無法使用相機",
                ko: "카메라를 사용할 수 없습니다", es: "Cámara no disponible",
                pt: "Câmera indisponível"
            ),
            isPresented: $showCameraUnavailable
        ) {
            Button("OK", role: .cancel) {}
        }
    }

    private var meetingTimeBinding: Binding<Date> {
        Binding(
            get: { plan.meetingAt ?? event?.date ?? Date() },
            set: { plan.meetingAt = $0 }
        )
    }

    private func loadIfNeeded() {
        guard !hasLoaded, let event else { return }
        plan = event.planning.meetingPlan
        hasMeetingTime = plan.meetingAt != nil
        hasLoaded = true
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraUnavailable = true
            return
        }
        showCamera = true
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            defer { pickerItem = nil }
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            plan.photoData = compressedPhoto(from: image)
        }
    }

    private func compressedPhoto(from image: UIImage) -> Data? {
        let maximumDimension: CGFloat = 1_600
        let largestDimension = max(image.size.width, image.size.height)
        guard largestDimension > 0 else { return nil }

        let ratio = min(1, maximumDimension / largestDimension)
        let resized: UIImage
        if ratio < 1 {
            let size = CGSize(
                width: image.size.width * ratio,
                height: image.size.height * ratio
            )
            resized = UIGraphicsImageRenderer(size: size).image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        } else {
            resized = image
        }
        return resized.jpegData(compressionQuality: 0.78)
    }

    private func save() {
        if viewModel.saveMeetingPlan(plan, in: eventId) {
            dismiss()
        }
    }
}
