import SwiftUI

struct EventCreateTutorialView: View {
    let language: AppLanguage
    let onFinish: () -> Void

    @State private var page = 0

    private func t(_ ja: String, _ en: String, _ zhHans: String, _ zhHant: String, _ ko: String, _ es: String, _ pt: String) -> String {
        language.text(ja: ja, en: en, zhHans: zhHans, zhHant: zhHant, ko: ko, es: es, pt: pt)
    }

    private var titles: [String] {[
        t("まず予定と期間を決めよう", "Set the event and schedule", "先设置活动和时间", "先設定活動和時間", "먼저 이벤트와 일정을 정해요", "Define el evento y las fechas", "Defina o evento e as datas"),
        t("予定人数だけでもOK", "Just set the headcount for now", "只填写预计人数也可以", "只填預計人數也可以", "예정 인원만 정해도 됩니다", "Con el número previsto basta", "Só o número previsto já basta"),
        t("使う通貨を選ぼう", "Choose the currency", "选择使用的货币", "選擇使用的貨幣", "사용할 통화를 선택하세요", "Elige la moneda", "Escolha a moeda"),
        t("費用の日付も残せる", "Track when expenses happened", "还可以记录费用日期", "也可以記錄費用日期", "비용 날짜도 기록할 수 있어요", "Guarda la fecha de cada gasto", "Registre a data de cada despesa"),
        t("精算して、そのまま共有", "Settle and share", "结算后直接分享", "結算後直接分享", "정산하고 바로 공유하세요", "Liquida y comparte", "Acerte e compartilhe")
    ]}

    private var descriptions: [String] {[
        t("イベント名・種類・開始日時・終了日時などを設定します。旅行のような複数日の予定にも対応しています。", "Set the event name, type, start and end time. Multi-day trips are supported too.", "设置活动名称、类型、开始和结束时间，也支持多日旅行。", "設定活動名稱、類型、開始與結束時間，也支援多日旅行。", "이벤트 이름, 유형, 시작 및 종료 시간을 설정합니다. 여러 날의 여행도 가능합니다.", "Configura el nombre, tipo, inicio y fin. También sirve para viajes de varios días.", "Configure nome, tipo, início e fim. Também funciona para viagens de vários dias."),
        t("まだ全員の名前が決まっていなくても大丈夫。予定人数だけ入れて、名前はイベント作成後に登録できます。", "You don't need everyone's name yet. Set the planned headcount and add names after creating the event.", "还不知道所有人的名字也没关系。先填写预计人数，创建活动后再登记姓名。", "還不知道所有人的名字也沒關係。先填預計人數，建立活動後再登記姓名。", "아직 모든 사람의 이름을 몰라도 괜찮습니다. 예정 인원만 설정하고 이벤트 생성 후 이름을 추가하세요.", "No necesitas saber todos los nombres. Indica el número previsto y añade los nombres después.", "Você não precisa saber todos os nomes. Defina o número previsto e adicione os nomes depois."),
        t("イベントごとに通貨を設定できます。海外旅行なら現地通貨を選んで、そのまま費用を入力できます。", "Each event can use its own currency. For trips abroad, choose the local currency.", "每个活动都可以设置不同货币。海外旅行时可以直接选择当地货币。", "每個活動都可以設定不同貨幣。海外旅行時可以直接選擇當地貨幣。", "이벤트마다 통화를 설정할 수 있습니다. 해외에서는 현지 통화를 선택할 수 있습니다.", "Cada evento puede usar su propia moneda. En un viaje puedes elegir la moneda local.", "Cada evento pode usar sua própria moeda. Em viagens, escolha a moeda local."),
        t("費用には任意で日付を付けられます。複数日のイベントでは「1日目・2日目…」ごとに自動でまとまり、その日の合計も確認できます。", "Dates are optional for expenses. In multi-day events, expenses are grouped by Day 1, Day 2 and so on, with daily totals.", "费用可选择记录日期。多日活动会自动按第1天、第2天等分组，并显示每天合计。", "費用可選擇記錄日期。多日活動會自動按第1天、第2天等分組，並顯示每天合計。", "비용에는 날짜를 선택적으로 기록할 수 있습니다. 여러 날의 이벤트에서는 1일차, 2일차별로 자동 정리되고 일별 합계도 표시됩니다.", "La fecha del gasto es opcional. En eventos de varios días se agrupa por Día 1, Día 2, etc., con totales diarios.", "A data da despesa é opcional. Em eventos de vários dias, as despesas são agrupadas por Dia 1, Dia 2 etc., com totais diários."),
        t("費用と支払者から負担額と送金先を自動計算。支払い状況を管理でき、予定や精算結果はテキスト・画像で共有できます。日付付き費用は日別内訳も共有されます。", "Warikanji calculates each share and transfer from expenses and payers. Track payments and share plans or settlements as text or images, including daily expense breakdowns when dates are used.", "根据费用和付款人自动计算分摊金额和转账对象，可管理付款状态，并以文字或图片分享活动和结算结果。记录日期的费用还会按天分享明细。", "根據費用和付款人自動計算分攤金額和轉帳對象，可管理付款狀態，並以文字或圖片分享活動和結算結果。記錄日期的費用還會按天分享明細。", "비용과 결제자를 바탕으로 부담액과 송금 대상을 자동 계산합니다. 결제 상태를 관리하고 일정과 정산 결과를 텍스트나 이미지로 공유할 수 있으며 날짜가 있는 비용은 일별 내역도 함께 공유됩니다.", "Warikanji calcula automáticamente cuánto corresponde a cada persona y las transferencias. Puedes controlar los pagos y compartir el evento o la liquidación como texto o imagen, con gastos por día cuando haya fechas.", "O Warikanji calcula automaticamente cada parte e as transferências. Você pode acompanhar pagamentos e compartilhar o evento ou o acerto em texto ou imagem, incluindo despesas por dia quando houver datas.")
    ]}

    private var skipText: String { t("スキップ", "Skip", "跳过", "略過", "건너뛰기", "Omitir", "Pular") }
    private var nextText: String { t("次へ", "Next", "下一步", "下一步", "다음", "Siguiente", "Próximo") }
    private var startText: String { t("予定を作ってみる", "Create an event", "开始创建活动", "開始建立活動", "이벤트 만들기", "Crear un evento", "Criar um evento") }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button(skipText) { onFinish() }
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                TabView(selection: $page) {
                    ForEach(titles.indices, id: \.self) { index in
                        tutorialPage(index).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if page < titles.count - 1 { withAnimation { page += 1 } }
                    else { onFinish() }
                } label: {
                    Text(page == titles.count - 1 ? startText : nextText)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(AppTheme.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 17))
                }
                .buttonStyle(.plain)
                .padding()
            }
        }
        .tint(AppTheme.primary)
    }

    private func tutorialPage(_ index: Int) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 10)

            preview(for: index)
                .frame(maxWidth: 360)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                Text(titles[index])
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(descriptions[index])
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
            }

            Spacer(minLength: 10)
        }
    }

    @ViewBuilder
    private func preview(for index: Int) -> some View {
        switch index {
        case 0: eventPreview
        case 1: participantPreview
        case 2: currencyPreview
        case 3: expenseDatePreview
        default: settlementPreview
        }
    }

    private var eventPreview: some View {
        VStack(spacing: 0) {
            mockHeader(title: t("新規イベント", "New Event", "新建活动", "新增活動", "새 이벤트", "Nuevo evento", "Novo evento"), symbol: "calendar.badge.plus")

            mockRow("pencil", t("イベント名", "Event Name", "活动名称", "活動名稱", "이벤트 이름", "Nombre", "Nome"), t("箱根旅行", "Hakone Trip", "箱根旅行", "箱根旅行", "하코네 여행", "Viaje a Hakone", "Viagem a Hakone"))

            Divider().padding(.leading, 48)

            mockRow("airplane", t("種類", "Type", "类型", "類型", "유형", "Tipo", "Tipo"), t("旅行", "Travel", "旅行", "旅行", "여행", "Viaje", "Viagem"))

            Divider().padding(.leading, 48)

            mockRow("calendar.badge.clock", t("開始日時", "Starts", "开始时间", "開始時間", "시작 일시", "Inicio", "Início"), "9/20 10:00")

            Divider().padding(.leading, 48)

            mockRow("calendar.badge.checkmark", t("終了日時", "Ends", "结束时间", "結束時間", "종료 일시", "Fin", "Fim"), "9/23 18:00")
        }
        .tutorialCard()
    }

    private var participantPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            mockHeader(title: t("参加予定人数", "Planned Participants", "预计人数", "預計人數", "예정 인원", "Participantes previstos", "Participantes previstos"), symbol: "person.3.fill")

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(t("予定", "Planned", "预计", "預計", "예정", "Previstos", "Previstos"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("6 \(language.participantUnit(for: 6))")
                        .font(.title2.bold())
                }

                Spacer()

                Stepper("", value: .constant(6), in: 1...20)
                    .labelsHidden()
                    .disabled(true)
            }

            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    VStack(spacing: 5) {
                        Circle()
                            .fill(index < 3 ? AppTheme.primary.opacity(0.15) : Color.secondary.opacity(0.08))
                            .frame(width: 38, height: 38)
                            .overlay {
                                Image(systemName: index < 3 ? "person.fill" : "questionmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(index < 3 ? AppTheme.primary : .secondary)
                            }

                        Text(index < 3 ? ["A", "B", "C"][index] : "—")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Label(t("名前はイベント作成後に登録できます", "Names can be added after creating the event", "创建活动后可以登记姓名", "建立活動後可以登記姓名", "이름은 이벤트 생성 후 추가할 수 있습니다", "Los nombres pueden añadirse después de crear el evento", "Os nomes podem ser adicionados depois de criar o evento"), systemImage: "info.circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .tutorialCard()
    }

    private var currencyPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            mockHeader(title: t("イベント通貨", "Event Currency", "活动货币", "活動貨幣", "이벤트 통화", "Moneda del evento", "Moeda do evento"), symbol: "banknote.fill")

            currencyRow("JPY", "¥", selected: false)
            currencyRow("USD", "US$", selected: true)
            currencyRow("EUR", "€", selected: false)

            HStack(spacing: 7) {
                Image(systemName: "airplane")
                    .foregroundStyle(AppTheme.primary)

                Text(t("海外旅行なら現地通貨を選択", "Use the local currency abroad", "海外旅行时选择当地货币", "海外旅行時選擇當地貨幣", "해외에서는 현지 통화를 선택", "Usa la moneda local en el extranjero", "Use a moeda local no exterior"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 2)
        }
        .tutorialCard()
    }

    private var expenseDatePreview: some View {
        VStack(alignment: .leading, spacing: 13) {
            mockHeader(title: t("費用の日付", "Expense Dates", "费用日期", "費用日期", "비용 날짜", "Fechas de gastos", "Datas das despesas"), symbol: "calendar")

            HStack {
                Label(t("日付を記録", "Add Date", "记录日期", "記錄日期", "날짜 기록", "Añadir fecha", "Adicionar data"), systemImage: "calendar.badge.plus")
                    .font(.subheadline.bold())

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.primary)
            }

            Divider()

            expenseDayPreview(t("1日目", "Day 1", "第1天", "第1天", "1일차", "Día 1", "Dia 1"), date: "9/20", total: "15,000", expenses: [
                (t("新幹線", "Train", "新干线", "新幹線", "신칸센", "Tren", "Trem"), "12,000"),
                (t("昼食", "Lunch", "午餐", "午餐", "점심", "Almuerzo", "Almoço"), "3,000")
            ])

            expenseDayPreview(t("2日目", "Day 2", "第2天", "第2天", "2일차", "Día 2", "Dia 2"), date: "9/21", total: "24,500", expenses: [
                (t("ホテル", "Hotel", "酒店", "飯店", "호텔", "Hotel", "Hotel"), "18,000"),
                (t("夕食", "Dinner", "晚餐", "晚餐", "저녁", "Cena", "Jantar"), "6,500")
            ])
        }
        .tutorialCard()
    }

    private var settlementPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            mockHeader(title: t("精算と共有", "Settlement & Sharing", "结算与分享", "結算與分享", "정산과 공유", "Liquidación y compartir", "Acerto e compartilhamento"), symbol: "arrow.left.arrow.right.circle.fill")

            HStack(spacing: 10) {
                mockAmount(symbol: "fork.knife", title: t("食事", "Food", "餐饮", "餐飲", "식사", "Comida", "Comida"), value: "12,000")

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                mockAmount(symbol: "person.fill", title: t("3人", "3 people", "3人", "3人", "3명", "3 personas", "3 pessoas"), value: "4,000")
            }

            Divider()

            VStack(spacing: 10) {
                transferRow("A", "B", "2,000")
                transferRow("C", "B", "2,000")
            }

            Divider()

            HStack(spacing: 10) {
                sharePreview(t("テキスト", "Text", "文字", "文字", "텍스트", "Texto", "Texto"), symbol: "text.bubble")
                sharePreview(t("画像", "Image", "图片", "圖片", "이미지", "Imagen", "Imagem"), symbol: "photo")
            }

            Label(t("日付付き費用は日別内訳も共有", "Dated expenses include a daily breakdown", "记录日期的费用会按天分享明细", "記錄日期的費用會按天分享明細", "날짜가 있는 비용은 일별 내역도 공유됩니다", "Los gastos con fecha incluyen el desglose diario", "Despesas com data incluem o detalhamento por dia"), systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(AppTheme.primary)
        }
        .tutorialCard()
    }

    private func mockHeader(title: String, symbol: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(title).font(.headline)
            Spacer()
        }
        .padding(.bottom, 3)
    }

    private func mockRow(_ symbol: String, _ title: String, _ value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 28)

            Text(title).font(.subheadline)
            Spacer()

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 11)
    }

    private func currencyRow(_ code: String, _ symbol: String, selected: Bool) -> some View {
        HStack {
            Text(symbol).font(.headline).frame(width: 38)
            Text(code).font(.subheadline.bold())
            Spacer()

            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? AppTheme.primary : .secondary)
        }
        .padding(12)
        .background(selected ? AppTheme.primary.opacity(0.08) : Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private func expenseDayPreview(_ title: String, date: String, total: String, expenses: [(String, String)]) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(title) · \(date)").font(.caption.bold())
                Spacer()
                Text("¥\(total)").font(.caption.bold().monospacedDigit())
            }

            ForEach(Array(expenses.enumerated()), id: \.offset) { _, expense in
                HStack {
                    Text("• \(expense.0)")
                    Spacer()
                    Text("¥\(expense.1)")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func mockAmount(symbol: String, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(AppTheme.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func transferRow(_ from: String, _ to: String, _ amount: String) -> some View {
        HStack {
            personCircle(from)

            Image(systemName: "arrow.right")
                .font(.caption)
                .foregroundStyle(.secondary)

            personCircle(to)

            Spacer()

            Text(amount)
                .font(.subheadline.bold().monospacedDigit())

            Image(systemName: "checkmark.circle")
                .foregroundStyle(.secondary)
        }
    }

    private func personCircle(_ text: String) -> some View {
        Circle()
            .fill(AppTheme.primary.opacity(0.12))
            .frame(width: 32, height: 32)
            .overlay {
                Text(text)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.primary)
            }
    }

    private func sharePreview(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.caption.bold())
            .foregroundStyle(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AppTheme.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private extension View {
    func tutorialCard() -> some View {
        padding(18)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.05), radius: 12, y: 5)
    }
}

#Preview {
    EventCreateTutorialView(language: .japanese) {}
}
