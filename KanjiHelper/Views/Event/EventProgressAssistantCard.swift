import SwiftUI

struct EventProgressAssistantCard: View {
    let event: Event
    let language: AppLanguage

    private var actions: [EventAssistantAction] {
        EventProgressAssistant.actions(for: event, language: language)
            .filter {
                [
                    "participants", "attendance", "parts", "tasks", "checklist",
                    "timeline", "schedule", "venue", "firstDrink", "meeting", "seating",
                    "reception", "budget", "settlement", "payments"
                ].contains($0.destinationKey)
            }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        if !actions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    language.text(
                        ja: "次にやること", en: "Next Steps",
                        zhHans: "下一步", zhHant: "下一步",
                        ko: "다음 할 일", es: "Siguientes pasos",
                        pt: "Próximos passos"
                    ),
                    systemImage: "sparkles"
                )
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

                ForEach(actions) { action in
                    actionLink(action)
                }
            }
            .appCard()
        }
    }

    @ViewBuilder
    private func actionLink(_ action: EventAssistantAction) -> some View {
        switch action.destinationKey {
        case "participants":
            NavigationLink {
                ParticipantManagementView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "attendance":
            NavigationLink {
                AttendanceManagementView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "parts":
            NavigationLink {
                EventPartsManagementView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "tasks":
            NavigationLink {
                EventTaskListView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "checklist":
            NavigationLink {
                EventChecklistView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "timeline":
            NavigationLink {
                EventTimelineView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "schedule":
            NavigationLink {
                SchedulePollView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "venue":
            NavigationLink {
                VenuePlanningView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "firstDrink":
            NavigationLink {
                FirstDrinkView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "meeting":
            NavigationLink {
                MeetingAndArrivalView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "seating":
            NavigationLink {
                SeatingPlanView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "reception":
            NavigationLink {
                ReceptionView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "budget":
            NavigationLink {
                EventBudgetView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "settlement":
            NavigationLink {
                SettlementResultView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        case "payments":
            NavigationLink {
                PaymentManagementView(eventId: event.id)
            } label: {
                actionRow(action)
            }
            .buttonStyle(.plain)
        default:
            EmptyView()
        }
    }

    private func actionRow(_ action: EventAssistantAction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: action.symbolName)
                .foregroundStyle(priorityColor(action.priority))
                .frame(width: 38, height: 38)
                .background(priorityColor(action.priority).opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(.subheadline.bold())

                Text(action.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(11)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func priorityColor(_ priority: EventAssistantPriority) -> Color {
        switch priority {
        case .critical: return AppTheme.danger
        case .high: return AppTheme.warning
        case .normal: return AppTheme.primary
        case .low: return .secondary
        }
    }
}
