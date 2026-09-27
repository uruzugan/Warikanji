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
    @State private var storageFailure: AppStorageOperation?

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
        .onAppear {
            if storageFailure == nil {
                storageFailure = AppStorageIssueReporter.takePendingOperation()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appStorageFailure)) { notification in
            _ = AppStorageIssueReporter.takePendingOperation()
            storageFailure = notification.object as? AppStorageOperation
        }
        .alert(
            storageFailureTitle,
            isPresented: Binding(
                get: { storageFailure != nil },
                set: { if !$0 { storageFailure = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(storageFailureMessage)
        }
    }

    private var storageFailureTitle: String {
        profileStore.activeLanguage.text(
            ja: "データ操作に失敗しました", en: "Data operation failed",
            zhHans: "数据操作失败", zhHant: "資料操作失敗",
            ko: "데이터 작업에 실패했습니다", es: "Error al gestionar los datos",
            pt: "Falha ao gerenciar os dados"
        )
    }

    private var storageFailureMessage: String {
        switch storageFailure {
        case .save:
            return profileStore.activeLanguage.text(
                ja: "変更を保存できませんでした。空き容量を確認して、もう一度お試しください。",
                en: "Your changes could not be saved. Check available storage and try again.",
                zhHans: "无法保存更改。请检查可用存储空间后重试。",
                zhHant: "無法儲存變更。請檢查可用儲存空間後再試一次。",
                ko: "변경 사항을 저장하지 못했습니다. 저장 공간을 확인한 후 다시 시도하세요.",
                es: "No se pudieron guardar los cambios. Comprueba el espacio disponible e inténtalo de nuevo.",
                pt: "Não foi possível salvar as alterações. Verifique o espaço disponível e tente novamente."
            )
        case .load:
            return profileStore.activeLanguage.text(
                ja: "保存済みデータの一部を読み込めませんでした。問題が続く場合はバックアップから復元してください。",
                en: "Some saved data could not be read. Restore a backup if the problem continues.",
                zhHans: "部分已保存数据无法读取。如果问题持续，请从备份恢复。",
                zhHant: "部分已儲存資料無法讀取。如果問題持續，請從備份還原。",
                ko: "저장된 데이터 일부를 읽지 못했습니다. 문제가 계속되면 백업에서 복원하세요.",
                es: "No se pudieron leer algunos datos guardados. Restaura una copia de seguridad si el problema continúa.",
                pt: "Alguns dados salvos não puderam ser lidos. Restaure um backup se o problema continuar."
            )
        case .delete:
            return profileStore.activeLanguage.text(
                ja: "データを削除できませんでした。もう一度お試しください。",
                en: "The data could not be deleted. Please try again.",
                zhHans: "无法删除数据。请重试。", zhHant: "無法刪除資料。請再試一次。",
                ko: "데이터를 삭제하지 못했습니다. 다시 시도하세요.",
                es: "No se pudieron eliminar los datos. Inténtalo de nuevo.",
                pt: "Não foi possível excluir os dados. Tente novamente."
            )
        case nil:
            return ""
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
