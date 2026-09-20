import SwiftUI

struct HowToUseView: View {
    struct Guide: Identifiable {
        let id: String
        let symbol: String
        let title: String
        let subtitle: String
        let steps: [String]
        var usesTutorial = false
    }

    @EnvironmentObject private var profileStore: ProfileStore
    @State private var showEventCreateTutorial = false
    @State private var selectedGuide: Guide?

    private var language: AppLanguage { profileStore.activeLanguage }

    private func t(_ ja: String, _ en: String, _ zhHans: String, _ zhHant: String, _ ko: String, _ es: String, _ pt: String) -> String {
        language.text(ja: ja, en: en, zhHans: zhHans, zhHant: zhHant, ko: ko, es: es, pt: pt)
    }

    private var guides: [Guide] {[
        Guide(
            id: "create", symbol: "calendar.badge.plus",
            title: t("イベント作成", "Creating Events", "创建活动", "建立活動", "이벤트 만들기", "Crear eventos", "Criar eventos"),
            subtitle: t("期間・人数・通貨を設定", "Set dates, people and currency", "设置时间、人数和货币", "設定時間、人數和貨幣", "기간, 인원, 통화 설정", "Configura fechas, personas y moneda", "Configure datas, pessoas e moeda"),
            steps: [], usesTutorial: true
        ),
        Guide(
            id: "participants", symbol: "person.3.fill",
            title: t("参加者", "Participants", "参与者", "參加者", "참가자", "Participantes", "Participantes"),
            subtitle: t("精算するメンバーを管理", "Manage people in the settlement", "管理结算成员", "管理結算成員", "정산 참가자 관리", "Gestiona los participantes", "Gerencie os participantes"),
            steps: [
                t("イベント作成時は予定人数だけ設定し、作成後に参加者名を登録できます。", "Set only the planned headcount when creating an event, then add participant names afterward.", "创建活动时只需设置预计人数，之后再登记参与者姓名。", "建立活動時只需設定預計人數，之後再登記參加者姓名。", "이벤트 생성 시 예정 인원만 설정하고 생성 후 참가자 이름을 등록할 수 있습니다.", "Al crear el evento basta con indicar el número previsto; los nombres se añaden después.", "Ao criar o evento, basta definir o número previsto; os nomes podem ser adicionados depois."),
                t("参加者名は費用の支払者や精算結果に使われます。", "Names are used for payers and settlement results.", "参与者姓名会用于付款人和结算结果。", "參加者姓名會用於付款人和結算結果。", "참가자 이름은 결제자와 정산 결과에 사용됩니다.", "Los nombres aparecen en pagos y liquidaciones.", "Os nomes aparecem nos pagamentos e acertos.")
            ]
        ),
        Guide(
            id: "expenses", symbol: "banknote.fill",
            title: t("費用", "Expenses", "费用", "費用", "비용", "Gastos", "Despesas"),
            subtitle: t("金額・負担方法・日付を記録", "Record amount, split and date", "记录金额、分摊方式和日期", "記錄金額、分攤方式和日期", "금액, 분담 방법, 날짜 기록", "Registra importe, reparto y fecha", "Registre valor, divisão e data"),
            steps: [
                t("費用名・金額・支払者を入力します。", "Enter the expense, amount and payer.", "输入费用名称、金额和付款人。", "輸入費用名稱、金額和付款人。", "비용명, 금액, 결제자를 입력합니다.", "Introduce el gasto, importe y pagador.", "Informe a despesa, valor e pagador."),
                t("必要なら「日付を記録」を有効にして、費用が発生した日を保存できます。", "Turn on Add Date when needed to record the day the expense occurred.", "需要时可开启记录日期，保存费用发生的日期。", "需要時可開啟記錄日期，儲存費用發生的日期。", "필요하면 날짜 기록을 켜서 비용이 발생한 날짜를 저장할 수 있습니다.", "Activa la fecha cuando quieras guardar el día en que ocurrió el gasto.", "Ative a data quando quiser registrar o dia em que a despesa ocorreu."),
                t("日付付きの費用がある場合は、1日目・2日目のように自動でまとめられ、日ごとの合計も表示されます。", "When expenses have dates, they are grouped automatically by Day 1, Day 2 and so on, with a total for each day.", "有日期的费用会自动按第1天、第2天等分组，并显示每天合计。", "有日期的費用會自動按第1天、第2天等分組，並顯示每天合計。", "날짜가 있는 비용은 1일차, 2일차처럼 자동으로 묶이고 일별 합계도 표시됩니다.", "Los gastos con fecha se agrupan automáticamente por Día 1, Día 2, etc., mostrando el total de cada día.", "Despesas com data são agrupadas automaticamente por Dia 1, Dia 2 etc., mostrando o total de cada dia."),
                t("均等割りやカスタム割り、丸め方法を設定できます。", "Choose equal/custom splitting and rounding.", "可设置平均分摊、自定义分摊和舍入方式。", "可設定平均分攤、自訂分攤和捨入方式。", "균등/사용자 지정 분할과 반올림을 설정할 수 있습니다.", "Puedes elegir reparto y redondeo.", "Você pode escolher divisão e arredondamento.")
            ]
        ),
        Guide(
            id: "settlement", symbol: "arrow.triangle.2.circlepath",
            title: t("精算", "Settlement", "结算", "結算", "정산", "Liquidación", "Acerto"),
            subtitle: t("誰がいくら負担するかを自動計算", "Automatically calculate each share", "自动计算每人的分摊金额", "自動計算每人的分攤金額", "각자의 부담액 자동 계산", "Calcula automáticamente cada parte", "Calcula automaticamente cada parte"),
            steps: [
                t("登録した費用から各参加者の負担額を計算します。", "Shares are calculated from registered expenses.", "根据已登记费用计算每人的负担额。", "根據已登記費用計算每人的負擔額。", "등록된 비용으로 각 참가자의 부담액을 계산합니다.", "Calcula cada parte a partir de los gastos.", "Calcula cada parte a partir das despesas."),
                t("必要な送金ルートも自動で計算されます。", "Required transfers are calculated automatically too.", "还会自动计算所需转账路线。", "也會自動計算所需轉帳路線。", "필요한 송금 경로도 자동으로 계산됩니다.", "También calcula automáticamente las transferencias necesarias.", "As transferências necessárias também são calculadas automaticamente."),
                t("内容が確定したら精算を確定すると編集をロックできます。支払い状況は確定後も更新できます。", "Finalize the settlement to lock event data. Payment status can still be updated afterward.", "确认后可锁定活动数据，付款状态仍可继续更新。", "確認後可鎖定活動資料，付款狀態仍可繼續更新。", "정산을 확정하면 이벤트 내용을 잠글 수 있으며 결제 상태는 이후에도 변경할 수 있습니다.", "Finaliza la liquidación para bloquear los datos; los pagos pueden seguir actualizándose.", "Finalize o acerto para bloquear os dados; os pagamentos ainda podem ser atualizados.")
            ]
        ),
        Guide(
            id: "payments", symbol: "checkmark.circle.fill",
            title: t("支払い", "Payments", "付款", "付款", "결제", "Pagos", "Pagamentos"),
            subtitle: t("送金状況をチェック", "Track payment progress", "跟踪付款状态", "追蹤付款狀態", "결제 진행 상황 확인", "Controla los pagos", "Acompanhe os pagamentos"),
            steps: [
                t("精算結果から必要な送金ルートが表示されます。", "Required transfers are shown from the settlement.", "结算后会显示所需转账路线。", "結算後會顯示所需轉帳路線。", "정산 결과에서 필요한 송금 경로가 표시됩니다.", "Se muestran las transferencias necesarias.", "As transferências necessárias são exibidas."),
                t("支払いが終わったものは支払い済みにできます。", "Mark completed transfers as paid.", "完成付款后可标记为已支付。", "完成付款後可標記為已支付。", "완료된 송금을 결제 완료로 표시할 수 있습니다.", "Marca los pagos completados.", "Marque pagamentos concluídos.")
            ]
        ),
        Guide(
            id: "search", symbol: "magnifyingglass",
            title: t("検索・絞り込み", "Search & Filters", "搜索与筛选", "搜尋與篩選", "검색 및 필터", "Búsqueda y filtros", "Pesquisa e filtros"),
            subtitle: t("イベントをすぐに探す", "Find events quickly", "快速查找活动", "快速尋找活動", "이벤트 빠르게 찾기", "Encuentra eventos rápidamente", "Encontre eventos rapidamente"),
            steps: [
                t("ホームの検索欄からイベント名・場所・メモを検索できます。", "Search event names, locations and notes from Home.", "可在主页搜索活动名称、地点和备注。", "可在首頁搜尋活動名稱、地點和備註。", "홈에서 이벤트명, 장소, 메모를 검색할 수 있습니다.", "Busca nombre, lugar y notas desde Inicio.", "Pesquise nome, local e notas na tela inicial."),
                t("絞り込みボタンからイベント種類を指定できます。", "Use the filter button to choose an event type.", "可通过筛选按钮指定活动类型。", "可透過篩選按鈕指定活動類型。", "필터 버튼에서 이벤트 종류를 선택할 수 있습니다.", "Filtra también por tipo de evento.", "Também é possível filtrar pelo tipo.")
            ]
        ),
        Guide(
            id: "archive", symbol: "archivebox.fill",
            title: t("アーカイブ", "Archive", "归档", "封存", "보관", "Archivo", "Arquivo"),
            subtitle: t("終了したイベントを整理", "Store finished events", "整理已结束活动", "整理已結束活動", "끝난 이벤트 정리", "Organiza eventos terminados", "Organize eventos concluídos"),
            steps: [
                t("イベントの終了日時を過ぎると、詳細画面に終了済みの案内が表示されます。", "After the event end time passes, the event detail screen shows that the event has ended.", "活动结束时间过后，详情页会显示活动已结束。", "活動結束時間過後，詳情頁會顯示活動已結束。", "이벤트 종료 시간이 지나면 상세 화면에 종료 안내가 표시됩니다.", "Cuando pasa la hora de fin, la pantalla del evento muestra que ha terminado.", "Quando o horário de término passa, a tela do evento indica que ele terminou."),
                t("イベントを長押しするか詳細画面の「…」からアーカイブできます。", "Archive from a long press or the “…” menu.", "长按活动或从详情页“…”中归档。", "長按活動或從詳情頁「…」中封存。", "길게 누르거나 상세 화면의 '…'에서 보관할 수 있습니다.", "Archiva manteniendo pulsado o desde «…».", "Arquive mantendo pressionado ou pelo menu '…'."),
                t("ホームのアーカイブタブからいつでも戻せます。", "Restore it anytime from the Archived tab.", "可随时从归档页恢复。", "可隨時從封存頁還原。", "보관 탭에서 언제든 복원할 수 있습니다.", "Puedes restaurarlo desde Archivados.", "Você pode restaurá-lo pela aba Arquivados.")
            ]
        ),
        Guide(
            id: "duplicate", symbol: "plus.square.on.square",
            title: t("イベント複製", "Duplicate Event", "复制活动", "複製活動", "이벤트 복제", "Duplicar evento", "Duplicar evento"),
            subtitle: t("似たイベントをすぐ作成", "Reuse an existing event", "快速复用已有活动", "快速重用已有活動", "기존 이벤트 재사용", "Reutiliza un evento existente", "Reutilize um evento existente"),
            steps: [
                t("詳細画面の「…」からイベントを複製できます。", "Choose Duplicate Event from the “…” menu.", "可从详情页“…”中复制活动。", "可從詳情頁「…」中複製活動。", "상세 화면의 '…'에서 이벤트를 복제할 수 있습니다.", "Usa «Duplicar evento» desde «…».", "Use 'Duplicar evento' no menu '…'."),
                t("開催期間・参加者・費用・費用の日付・負担条件はコピーされます。", "The schedule, participants, expenses, expense dates and splitting conditions are copied.", "活动时间、参与者、费用、费用日期和分摊条件会被复制。", "活動時間、參加者、費用、費用日期和分攤條件會被複製。", "이벤트 기간, 참가자, 비용, 비용 날짜, 부담 조건이 복사됩니다.", "Se copian fechas, participantes, gastos, fechas de gastos y condiciones de reparto.", "Período, participantes, despesas, datas e condições de divisão são copiados."),
                t("支払い状況・ロック状態・レシート写真は引き継ぎません。", "Payment status, lock state and receipt photos are not copied.", "付款状态、锁定状态和收据照片不会复制。", "付款狀態、鎖定狀態和收據照片不會複製。", "결제 상태, 잠금 상태, 영수증 사진은 복사되지 않습니다.", "No se copian los pagos, el bloqueo ni las fotos de recibos.", "Pagamentos, bloqueio e fotos de recibos não são copiados.")
            ]
        ),
        Guide(
            id: "receipts", symbol: "receipt.fill",
            title: t("レシート写真", "Receipt Photos", "收据照片", "收據照片", "영수증 사진", "Fotos de recibos", "Fotos de recibos"),
            subtitle: t("費用に写真を保存", "Attach photos to expenses", "为费用添加照片", "為費用新增照片", "비용에 사진 첨부", "Adjunta fotos a los gastos", "Anexe fotos às despesas"),
            steps: [
                t("費用の追加・編集画面から最大3枚まで保存できます。", "Attach up to 3 photos when adding or editing an expense.", "添加或编辑费用时最多可保存3张照片。", "新增或編輯費用時最多可儲存3張照片。", "비용 추가·편집 시 최대 3장까지 저장할 수 있습니다.", "Guarda hasta 3 fotos por gasto.", "Salve até 3 fotos por despesa."),
                t("写真をタップすると拡大して確認できます。", "Tap a photo to view it larger.", "点击照片可放大查看。", "點擊照片可放大查看。", "사진을 탭하면 크게 볼 수 있습니다.", "Toca una foto para ampliarla.", "Toque em uma foto para ampliá-la.")
            ]
        ),
        Guide(
            id: "share", symbol: "square.and.arrow.up.fill",
            title: t("イベント・精算を共有", "Share Events & Settlement", "分享活动与结算", "分享活動與結算", "이벤트·정산 공유", "Compartir evento y liquidación", "Compartilhar evento e acerto"),
            subtitle: t("テキスト・画像で送信", "Share as text or image", "以文字或图片分享", "以文字或圖片分享", "텍스트 또는 이미지로 공유", "Comparte texto o imagen", "Compartilhe texto ou imagem"),
            steps: [
                t("イベント詳細の「…」から、予定をテキストまたは共有カードで送れます。", "From the event “…” menu, share the plan as text or an image card.", "可从活动详情“…”中以文字或图片卡片分享计划。", "可從活動詳情「…」中以文字或圖片卡片分享計畫。", "이벤트 상세의 '…'에서 일정을 텍스트 또는 이미지 카드로 공유할 수 있습니다.", "Desde «…» en el evento puedes compartir el plan como texto o tarjeta.", "No menu '…' do evento, compartilhe o plano em texto ou cartão."),
                t("精算画面右上から、精算結果もテキストまたは画像で共有できます。", "Use the button at the top right of the settlement screen to share the result as text or an image.", "可从结算页面右上角以文字或图片分享结算结果。", "可從結算頁面右上角以文字或圖片分享結算結果。", "정산 화면 오른쪽 위에서 결과를 텍스트 또는 이미지로 공유할 수 있습니다.", "Desde la esquina superior derecha de la liquidación puedes compartir el resultado como texto o imagen.", "No canto superior direito do acerto, compartilhe o resultado em texto ou imagem."),
                t("日付を付けた費用がある場合、共有内容にも1日目・2日目ごとの費用と日別合計が入ります。", "If expenses have dates, shared content also includes expenses and totals for each day.", "如果费用记录了日期，分享内容也会包含每天的费用和合计。", "如果費用記錄了日期，分享內容也會包含每天的費用和合計。", "날짜가 있는 비용은 공유 내용에도 일자별 비용과 합계가 포함됩니다.", "Si los gastos tienen fecha, el contenido compartido incluye los gastos y totales de cada día.", "Se as despesas tiverem data, o conteúdo compartilhado inclui despesas e totais de cada dia.")
            ]
        )
    ]}

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerCard
                guideCard
            }
            .padding()
            .padding(.bottom, 30)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle(t("使い方", "How to Use", "使用方法", "使用方法", "사용 방법", "Cómo usar", "Como usar"))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showEventCreateTutorial) {
            EventCreateTutorialView(language: language) { showEventCreateTutorial = false }
        }
        .sheet(item: $selectedGuide) { guide in
            GuideDetailView(guide: guide).environmentObject(profileStore)
        }
        .tint(AppTheme.primary)
    }

    private var headerCard: some View {
        HStack(spacing: 15) {
            Image(systemName: "book.pages.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 4) {
                Text(t("ワリカンジの使い方", "Learn Warikanji", "Warikanji 使用方法", "Warikanji 使用方法", "Warikanji 사용 방법", "Aprende Warikanji", "Aprenda Warikanji"))
                    .font(.headline)

                Text(t("基本操作から便利機能まで、いつでも確認できます。", "Review basic controls and useful features anytime.", "随时查看基本操作和实用功能。", "隨時查看基本操作和實用功能。", "기본 사용법과 편리한 기능을 언제든 확인할 수 있습니다.", "Consulta las funciones básicas y útiles cuando quieras.", "Consulte funções básicas e úteis quando quiser."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .appCard()
    }

    private var guideCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(guides.enumerated()), id: \.element.id) { index, guide in
                Button {
                    if guide.usesTutorial { showEventCreateTutorial = true }
                    else { selectedGuide = guide }
                } label: {
                    HStack(spacing: 13) {
                        Image(systemName: guide.symbol)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppTheme.primary)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(guide.title).font(.subheadline.bold()).foregroundStyle(.primary)
                            Text(guide.subtitle).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                        }

                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < guides.count - 1 { Divider().padding(.leading, 56) }
            }
        }
        .appCard()
    }
}

private struct GuideDetailView: View {
    let guide: HowToUseView.Guide

    @EnvironmentObject private var profileStore: ProfileStore
    @Environment(\.dismiss) private var dismiss

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Image(systemName: guide.symbol)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(AppTheme.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 22))

                    Text(guide.title).font(.title2.bold())
                    Text(guide.subtitle).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)

                    VStack(spacing: 0) {
                        ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 26, height: 26)
                                    .background(AppTheme.primary)
                                    .clipShape(Circle())

                                Text(step).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 13)

                            if index < guide.steps.count - 1 { Divider().padding(.leading, 38) }
                        }
                    }
                    .appCard()
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(guide.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(tClose) { dismiss() }
                }
            }
        }
        .tint(AppTheme.primary)
    }

    private var tClose: String {
        language.text(ja: "閉じる", en: "Close", zhHans: "关闭", zhHant: "關閉", ko: "닫기", es: "Cerrar", pt: "Fechar")
    }
}

#Preview {
    NavigationStack {
        HowToUseView().environmentObject(ProfileStore())
    }
}
