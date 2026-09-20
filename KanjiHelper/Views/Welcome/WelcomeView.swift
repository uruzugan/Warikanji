import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @AppStorage("hasSeenEventCreateTutorial") private var hasSeenEventCreateTutorial = false
    @FocusState private var isNameFocused: Bool

    @State private var name = ""
    @State private var language = AppLanguage.deviceDefault
    @State private var homeCurrency = AppCurrency.deviceDefault()
    @State private var referenceCurrency = AppCurrency.deviceDefault()
    @State private var showTutorial = false

    private var isJapanese: Bool { language == .japanese }
    private var isCreateDisabled: Bool { name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private func text(_ ja: String, _ en: String) -> String { isJapanese ? ja : en }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    featureCard
                    accountCard
                    preferenceCard
                    startButton
                }
                .padding()
                .padding(.bottom, 32)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(text("完了", "Done")) { isNameFocused = false }
                }
            }
        }
        .tint(AppTheme.primary)
        .fullScreenCover(isPresented: $showTutorial) {
            EventCreateTutorialView(language: language) { finishTutorialAndStart() }
                .interactiveDismissDisabled()
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(AppTheme.gradient)
                    .frame(width: 92, height: 92)

                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: AppTheme.primary.opacity(0.25), radius: 14, y: 7)

            VStack(spacing: 6) {
                Text(language.appName)
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text(language.tagline)
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 30)
    }

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(text("幹事をもっとシンプルに", "Make organizing easier"))
                .font(.headline)

            featureRow(symbol: "banknote.fill", text: text("費用をまとめて記録", "Track group expenses"))
            featureRow(symbol: "slider.horizontal.3", text: text("負担額をかんたん調整", "Adjust each person's share"))
            featureRow(symbol: "arrow.left.arrow.right", text: text("誰が誰に払うか自動計算", "Calculate who pays whom"))
            featureRow(symbol: "checkmark.circle.fill", text: text("支払い状況まで確認", "Track payment status"))
        }
        .appCard()
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(text("あなたのアカウント", "Your account"), systemImage: "person.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

            TextField(text("名前", "Name"), text: $name)
                .textContentType(.name)
                .focused($isNameFocused)
                .inputStyle()

            Text(text(
                "端末内に保存されるローカルアカウントです。",
                "This account is stored locally on this device."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .appCard()
    }

    private var preferenceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(text("言語と通貨", "Language & Currency"), systemImage: "globe")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

            preferenceRow(title: "Language") {
                Picker("", selection: $language) {
                    ForEach(AppLanguage.allCases) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .labelsHidden()
            }

            Divider()

            preferenceRow(title: text("ホーム通貨", "Home currency")) {
                currencyPicker(selection: $homeCurrency)
            }

            Divider()

            preferenceRow(title: text("参考換算先", "Reference currency")) {
                currencyPicker(selection: $referenceCurrency)
            }

            Text(text(
                "海外イベントでは現地通貨の合計と、ここで選んだ通貨への参考換算額を表示できます。",
                "For overseas events, Warikanji can show both the local total and an approximate value in your reference currency."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .appCard()
    }

    private var startButton: some View {
        Button { startTutorial() } label: {
            Text(text("ワリカンジをはじめる", "Start Warikanji"))
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AppTheme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isCreateDisabled)
        .opacity(isCreateDisabled ? 0.45 : 1)
    }

    private func featureRow(symbol: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 34, height: 34)
                .background(AppTheme.primary.opacity(0.1))
                .clipShape(Circle())

            Text(text).font(.subheadline)
            Spacer()
        }
    }

    private func preferenceRow<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Text(title).font(.subheadline.bold())
            Spacer()
            content()
        }
    }

    private func currencyPicker(selection: Binding<AppCurrency>) -> some View {
        Picker("", selection: selection) {
            ForEach(AppCurrency.allCases) { currency in
                Text(currency.pickerTitle(for: language)).tag(currency)
            }
        }
        .labelsHidden()
    }

    private func startTutorial() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        isNameFocused = false
        showTutorial = true
    }

    private func finishTutorialAndStart() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            showTutorial = false
            return
        }

        hasSeenEventCreateTutorial = true

        profileStore.createProfile(
            name: trimmedName,
            language: language,
            homeCurrency: homeCurrency,
            referenceCurrency: referenceCurrency
        )

        showTutorial = false
    }
}

#Preview {
    WelcomeView()
        .environmentObject(ProfileStore())
}
