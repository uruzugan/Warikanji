import SwiftUI
import UniformTypeIdentifiers

struct AppSettingsView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var eventViewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var language: AppLanguage = .japanese
    @State private var homeCurrency: AppCurrency = .jpy
    @State private var referenceCurrency: AppCurrency = .jpy
    @State private var showDeleteConfirmation = false
    @State private var showSaved = false
    @State private var hasLoaded = false
    @State private var backupDocument: WarikanjiBackupDocument?
    @State private var pendingRestoreData: Data?
    @State private var isExportingBackup = false
    @State private var isImportingBackup = false
    @State private var showRestoreConfirmation = false
    @State private var backupStatus: BackupStatus?

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
                    backupCard
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
                        if save(showConfirmation: false) {
                            dismiss()
                        }
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear { loadIfNeeded() }
            .alert(language.t(.settingsSaved), isPresented: $showSaved) {
                Button("OK", role: .cancel) {}
            }
            .alert(backupStatusTitle, isPresented: Binding(
                get: { backupStatus != nil },
                set: { if !$0 { backupStatus = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(backupStatusMessage)
            }
            .fileExporter(
                isPresented: $isExportingBackup,
                document: backupDocument,
                contentType: .json,
                defaultFilename: backupFileName
            ) { result in
                if case .success = result {
                    backupStatus = .exported
                } else {
                    backupStatus = .exportFailed
                }
                backupDocument = nil
            }
            .fileImporter(
                isPresented: $isImportingBackup,
                allowedContentTypes: [.json]
            ) { result in
                prepareRestore(from: result)
            }
            .confirmationDialog(
                t(
                    "バックアップから復元しますか？", "Restore from this backup?",
                    "要从此备份恢复吗？", "要從此備份還原嗎？",
                    "이 백업에서 복원하시겠습니까?", "¿Restaurar desde esta copia?",
                    "Restaurar deste backup?"
                ),
                isPresented: $showRestoreConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    t("復元する", "Restore", "恢复", "還原", "복원", "Restaurar", "Restaurar"),
                    role: .destructive,
                    action: restoreBackup
                )
                Button(language.t(.cancel), role: .cancel) {
                    pendingRestoreData = nil
                }
            } message: {
                Text(
                    t(
                        "端末内のアカウント、イベント、費用、精算状況、レシート画像をバックアップの内容で置き換えます。",
                        "Accounts, events, expenses, settlement status and receipt images on this device will be replaced with the backup.",
                        "本设备上的账户、活动、费用、结算状态和收据图片将被备份内容替换。",
                        "本裝置上的帳戶、活動、費用、結算狀態和收據圖片將由備份內容取代。",
                        "이 기기의 계정, 이벤트, 비용, 정산 상태 및 영수증 이미지가 백업 내용으로 교체됩니다.",
                        "Las cuentas, eventos, gastos, liquidaciones e imágenes de recibos del dispositivo se sustituirán por la copia.",
                        "As contas, eventos, despesas, acertos e imagens de recibos do dispositivo serão substituídos pelo backup."
                    )
                )
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

            settingsLine(title: language.t(.language), symbol: "globe") {
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

    private var backupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle(
                t(
                    "バックアップと復元", "Backup & Restore",
                    "备份与恢复", "備份與還原", "백업 및 복원",
                    "Copia y restauración", "Backup e restauração"
                ),
                symbol: "externaldrive.fill"
            )

            Text(
                t(
                    "すべてのローカルアカウントとレシート画像を1つのファイルに保存します。保存先を選ぶまで端末外には送信されません。",
                    "Save every local account and receipt image in one file. Nothing leaves your device until you choose where to save it.",
                    "将所有本地账户和收据图片保存为一个文件。在您选择保存位置之前，数据不会离开设备。",
                    "將所有本機帳戶和收據圖片儲存為一個檔案。在您選擇儲存位置之前，資料不會離開裝置。",
                    "모든 로컬 계정과 영수증 이미지를 하나의 파일에 저장합니다. 저장 위치를 선택하기 전에는 기기 밖으로 전송되지 않습니다.",
                    "Guarda todas las cuentas locales y los recibos en un archivo. Nada sale del dispositivo hasta que eliges dónde guardarlo.",
                    "Salve todas as contas locais e imagens de recibos em um arquivo. Nada sai do dispositivo até você escolher onde salvar."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Button(action: exportBackup) {
                Label(
                    t(
                        "バックアップを書き出す", "Export Backup",
                        "导出备份", "匯出備份", "백업 내보내기",
                        "Exportar copia", "Exportar backup"
                    ),
                    systemImage: "square.and.arrow.up"
                )
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(AppTheme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                isImportingBackup = true
            } label: {
                Label(
                    t(
                        "バックアップから復元", "Restore Backup",
                        "从备份恢复", "從備份還原", "백업에서 복원",
                        "Restaurar copia", "Restaurar backup"
                    ),
                    systemImage: "square.and.arrow.down"
                )
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
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
                if save(showConfirmation: false) {
                    profileStore.leaveCurrentProfile()
                    dismiss()
                }
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

    @discardableResult
    private func save(showConfirmation: Bool = true) -> Bool {
        guard !trimmedName.isEmpty else { return false }

        let saved = profileStore.updateActiveSettings(
            name: trimmedName,
            language: language,
            homeCurrency: homeCurrency,
            referenceCurrency: referenceCurrency
        )

        if saved, showConfirmation {
            showSaved = true
        }
        return saved
    }

    private func exportBackup() {
        do {
            backupDocument = WarikanjiBackupDocument(
                data: try profileStore.exportBackupData()
            )
            isExportingBackup = true
        } catch {
            backupStatus = .exportFailed
        }
    }

    private func prepareRestore(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }

            let data = try Data(contentsOf: url)
            _ = try BackupService.shared.decode(data)
            pendingRestoreData = data
            showRestoreConfirmation = true
        } catch {
            backupStatus = .restoreFailed
        }
    }

    private func restoreBackup() {
        guard let pendingRestoreData else { return }

        do {
            try profileStore.restoreBackupData(pendingRestoreData)

            if let activeProfileId = profileStore.activeProfileId {
                eventViewModel.switchProfile(to: activeProfileId)
            } else {
                eventViewModel.unloadProfile()
            }

            hasLoaded = false
            loadIfNeeded()
            backupStatus = .restored
        } catch {
            backupStatus = .restoreFailed
        }

        self.pendingRestoreData = nil
    }

    private var backupFileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "Warikanji-Backup-\(formatter.string(from: Date()))"
    }

    private var backupStatusTitle: String {
        switch backupStatus {
        case .exported:
            return t(
                "バックアップ完了", "Backup Complete", "备份完成", "備份完成",
                "백업 완료", "Copia completada", "Backup concluído"
            )
        case .restored:
            return t(
                "復元完了", "Restore Complete", "恢复完成", "還原完成",
                "복원 완료", "Restauración completada", "Restauração concluída"
            )
        case .exportFailed, .restoreFailed, nil:
            return t(
                "処理できませんでした", "Could Not Complete",
                "无法完成操作", "無法完成操作", "작업을 완료하지 못했습니다",
                "No se pudo completar", "Não foi possível concluir"
            )
        }
    }

    private var backupStatusMessage: String {
        switch backupStatus {
        case .exported:
            return t(
                "バックアップファイルを保存しました。", "The backup file was saved.",
                "备份文件已保存。", "備份檔案已儲存。", "백업 파일을 저장했습니다.",
                "Se guardó el archivo de copia.", "O arquivo de backup foi salvo."
            )
        case .restored:
            return t(
                "バックアップの内容を復元しました。", "The backup was restored.",
                "备份内容已恢复。", "備份內容已還原。", "백업 내용을 복원했습니다.",
                "Se restauró la copia de seguridad.", "O backup foi restaurado."
            )
        case .exportFailed:
            return t(
                "バックアップを作成または保存できませんでした。もう一度お試しください。",
                "The backup could not be created or saved. Please try again.",
                "无法创建或保存备份。请重试。", "無法建立或儲存備份。請再試一次。",
                "백업을 만들거나 저장하지 못했습니다. 다시 시도하세요.",
                "No se pudo crear o guardar la copia. Inténtalo de nuevo.",
                "Não foi possível criar ou salvar o backup. Tente novamente."
            )
        case .restoreFailed:
            return t(
                "このファイルを復元できませんでした。有効なワリカンジのバックアップか確認してください。",
                "This file could not be restored. Make sure it is a valid Warikanji backup.",
                "无法恢复此文件。请确认它是有效的 Warikanji 备份。",
                "無法還原此檔案。請確認它是有效的 Warikanji 備份。",
                "이 파일을 복원하지 못했습니다. 올바른 Warikanji 백업인지 확인하세요.",
                "No se pudo restaurar el archivo. Comprueba que sea una copia válida de Warikanji.",
                "Não foi possível restaurar o arquivo. Confirme se é um backup válido do Warikanji."
            )
        case nil:
            return ""
        }
    }

    private func deleteAccount() {
        if profileStore.deleteActiveProfile() {
            dismiss()
        }
    }
}

#Preview {
    AppSettingsView()
        .environmentObject(ProfileStore())
        .environmentObject(EventViewModel())
}

private enum BackupStatus {
    case exported
    case restored
    case exportFailed
    case restoreFailed
}

private struct WarikanjiBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
