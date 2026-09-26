import SwiftUI
import EventKit
import EventKitUI
import UIKit

struct CalendarEventEditView: UIViewControllerRepresentable {
    let event: Event
    let language: AppLanguage

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> CalendarHostViewController {
        CalendarHostViewController(event: event, language: language) { dismiss() }
    }

    func updateUIViewController(_ uiViewController: CalendarHostViewController, context: Context) {}
}

final class CalendarHostViewController: UIViewController, EKEventEditViewDelegate {
    private let event: Event
    private let language: AppLanguage
    private let eventStore = EKEventStore()
    private let onDismiss: () -> Void
    private var hasStarted = false

    init(event: Event, language: AppLanguage, onDismiss: @escaping () -> Void) {
        self.event = event
        self.language = language
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasStarted else { return }
        hasStarted = true

        requestCalendarAccess()
    }

    private func requestCalendarAccess() {
        eventStore.requestWriteOnlyAccessToEvents { [weak self] granted, _ in
            DispatchQueue.main.async {
                guard let self else { return }

                if granted {
                    self.presentEditor()
                } else {
                    self.onDismiss()
                }
            }
        }
    }

    private func presentEditor() {
        let controller = EKEventEditViewController()
        let calendarEvent = EKEvent(eventStore: eventStore)

        calendarEvent.title = event.displayTitle(for: language)
        calendarEvent.startDate = event.date
        calendarEvent.endDate = max(event.endDate, event.date)

        let location = event.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let memo = event.memo.trimmingCharacters(in: .whitespacesAndNewlines)

        if !location.isEmpty {
            calendarEvent.location = location
        }

        if !memo.isEmpty {
            calendarEvent.notes = memo
        }

        controller.eventStore = eventStore
        controller.event = calendarEvent
        controller.editViewDelegate = self

        present(controller, animated: true)
    }

    func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    ) {
        controller.dismiss(animated: true) { [weak self] in
            self?.onDismiss()
        }
    }
}
