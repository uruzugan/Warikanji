import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var language: AppLanguage = .japanese
    @State private var homeCurrency: AppCurrency = .jpy
    @State private var referenceCurrency: AppCurrency = .jpy
    @State private var showDeleteConfirmation = false
    @State private var showSaved = false
    @State private var hasLoaded = false

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func t(_ ja: String, _ en: String, _ zhHans: String, _ zhHant: String, _ ko: String, _ es: String, _ pt: String) -> String {
        language.text(ja: ja, en: en, zhHans: zhHans, zhHant: zhHant, ko: ko, es: es, pt: pt)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    brandCard
                    accountCard
                    generalCard
                    helpCard
                    switchAccountCard
                    deleteAccountCard
                }
                .padding()
                .padding(.bottom, 32)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(language.t(.settings))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.t(.done)) {
                        save(showConfirmation: false)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear { loadIfNeeded() }
            .alert(language.t(.settingsSaved), isPresented: $showSaved) {
                Button("OK", role: .cancel) {}
            }
            .confirmationDialog(
                t("このアカウントを削除しますか？", "Delete this account?", "删除此账户？", "刪除此帳戶？", "이 계정을 삭제하시겠습니까?", "¿Eliminar esta cuenta?", "Excluir esta conta?"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    t("アカウントを削除", "Delete Account", "删除账户", "刪除帳戶", "계정 삭제", "Eliminar cuenta", "Excluir conta"),
                    role: .destructive
                ) {
                    deleteAccount()
                }

                Button(
                    t("キャンセル", "Cancel", "取消", "取消", "취소", "Cancelar", "Cancelar"),
                    role: .cancel
                ) {}
            } message: {
                Text(
                    t(
                        "このアカウントのイベント・費用・精算データも削除されます。この操作は取り消せません。",
                        "All events, expenses and settlement data for this account will also be deleted. This cannot be undone.",
                        "此账户中的活动、费用和结算数据也将被删除。此操作无法撤销。",
                        "此帳戶中的活動、費用和結算資料也將被刪除。此操作無法復原。",
                        "이 계정의 이벤트, 비용 및 정산 데이터도 삭제됩니다. 이 작업은 되돌릴 수 없습니다.",
                        "También se eliminarán los eventos, gastos y datos de liquidación de esta cuenta. Esta acción no se puede deshacer.",
                        "Os eventos, despesas e dados de acerto desta conta também serão excluídos. Esta ação não pode ser desfeita."
                    )
                )
            }
        }
        .tint(AppTheme.primary)
    }

    private var brandCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 17))

            VStack(alignment: .leading, spacing: 3) {
                Text(language.appName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text(language.tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .appCard()
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle(
                t("現在のアカウント", "Current Account", "当前账户", "目前帳戶", "현재 계정", "Cuenta actual", "Conta atual"),
                symbol: "person.crop.circle.fill"
            )

            TextField(
                t("名前", "Name", "姓名", "姓名", "이름", "Nombre", "Nome"),
                text: $name
            )
            .inputStyle()

            Text(
                t(
                    "名前はいつでも変更できます。",
                    "You can change your name at any time.",
                    "姓名可以随时修改。",
                    "姓名可以隨時修改。",
                    "이름은 언제든 변경할 수 있습니다.",
                    "Puedes cambiar tu nombre en cualquier momento.",
                    "Você pode alterar seu nome a qualquer momento."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .appCard()
    }

    private var generalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            cardTitle(language.t(.general), symbol: "gearshape.fill")

            settingsLine(title: "Language", symbol: "globe") {
                Menu {
                    ForEach(AppLanguage.allCases) { item in
                        Button { language = item } label: {
                            HStack {
                                Text(item.displayName)

                                if language == item {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    settingValueLabel(language.displayName)
                }
            }

            Divider()

            settingsLine(title: language.t(.homeCurrency), symbol: "house.fill") {
                currencyMenu(selection: $homeCurrency)
            }

            Divider()

            settingsLine(title: language.t(.referenceCurrency), symbol: "arrow.left.arrow.right") {
                currencyMenu(selection: $referenceCurrency)
            }

            Text(language.t(.currencySettingsDescription))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button { save() } label: {
                Label(language.t(.saveSettings), systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(trimmedName.isEmpty)
            .opacity(trimmedName.isEmpty ? 0.45 : 1)
        }
        .appCard()
    }

    private var helpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle(
                t("使い方", "How to Use", "使用方法", "使用方法", "사용 방법", "Cómo usar", "Como usar"),
                symbol: "book.fill"
            )

            Text(
                t(
                    "基本操作や便利な機能をいつでも確認できます。",
                    "Review basic controls and useful features anytime.",
                    "可以随时查看基本操作和实用功能。",
                    "可以隨時查看基本操作和實用功能。",
                    "기본 사용법과 편리한 기능을 언제든 확인할 수 있습니다.",
                    "Consulta las funciones básicas y útiles cuando quieras.",
                    "Consulte funções básicas e úteis quando quiser."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            NavigationLink {
                HowToUseView()
                    .environmentObject(profileStore)
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(AppTheme.primary)

                    Text(
                        t("使い方を見る", "View Guides", "查看教程", "查看教學", "사용 방법 보기", "Ver guías", "Ver guias")
                    )
                    .font(.subheadline.bold())

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(AppTheme.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .appCard()
    }

    private var switchAccountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle(language.t(.account), symbol: "person.2.circle.fill")

            Text(language.t(.switchAccountDescription))
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                save(showConfirmation: false)
                profileStore.leaveCurrentProfile()
                dismiss()
            } label: {
                Label(language.t(.switchAccount), systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .appCard()
    }

    private var deleteAccountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle(
                language.t(.deleteAccount),
                symbol: "trash.fill",
                color: AppTheme.danger
            )

            Text(language.t(.deleteAccountDescription))
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label(language.t(.deleteThisAccount), systemImage: "trash")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
        }
        .appCard()
    }

    private func settingsLine<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 28)

            Text(title)
                .font(.subheadline.bold())
                .lineLimit(2)
                .layoutPriority(1)

            Spacer(minLength: 12)
            content()
        }
        .frame(minHeight: 44)
    }

    private func settingValueLabel(_ value: String) -> some View {
        HStack(spacing: 5) {
            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppTheme.primary)
                .lineLimit(1)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.bold())
                .foregroundStyle(AppTheme.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppTheme.primary.opacity(0.08))
        .clipShape(Capsule())
    }

    private func currencyMenu(selection: Binding<AppCurrency>) -> some View {
        Menu {
            ForEach(AppCurrency.allCases) { currency in
                Button {
                    selection.wrappedValue = currency
                } label: {
                    HStack {
                        Text(currency.pickerTitle(for: language))

                        if selection.wrappedValue == currency {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            settingValueLabel(selection.wrappedValue.code)
        }
    }

    private func cardTitle(
        _ title: String,
        symbol: String,
        color: Color = AppTheme.primary
    ) -> some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .foregroundStyle(color)
    }

    private func loadIfNeeded() {
        guard !hasLoaded, let profile = profileStore.activeProfile else { return }

        name = profile.name
        language = profile.language
        homeCurrency = profile.homeCurrency
        referenceCurrency = profile.referenceCurrency
        hasLoaded = true
    }

    private func save(showConfirmation: Bool = true) {
        guard !trimmedName.isEmpty else { return }

        profileStore.renameActiveProfile(to: trimmedName)
        profileStore.updateActivePreferences(
            language: language,
            homeCurrency: homeCurrency,
            referenceCurrency: referenceCurrency
        )

        if showConfirmation {
            showSaved = true
        }
    }

    private func deleteAccount() {
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            profileStore.deleteActiveProfile()
        }
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(ProfileStore())
}
