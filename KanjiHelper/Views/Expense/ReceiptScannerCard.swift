import SwiftUI
import PhotosUI
import UIKit

struct ReceiptScannerCard: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Binding var imageData: [Data]

    let currency: AppCurrency
    let onApply: (ReceiptOCRResult) -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var isScanning = false
    @State private var scanResult: ReceiptOCRResult?
    @State private var errorMessage: String?

    private var language: AppLanguage { profileStore.activeLanguage }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                text(
                    "レシートから費用を入力", "Enter Expense from Receipt",
                    "从收据输入费用", "從收據輸入費用", "영수증으로 비용 입력",
                    "Introducir gasto desde recibo", "Inserir despesa pelo recibo"
                ),
                systemImage: "doc.text.viewfinder"
            )
            .font(.headline)
            .foregroundStyle(AppTheme.primary)

            Text(text(
                "撮影または写真を選ぶと、費用名・金額・日付を読み取れます。画像は空きがあれば添付写真にも保存されます。",
                "Take or choose a photo to read the expense name, amount, and date. If space is available, it is also saved as an attachment.",
                "拍摄或选择照片后，可识别费用名称、金额和日期。如有空位，该图片也会保存为附件。",
                "拍攝或選擇照片後，可辨識費用名稱、金額和日期。如有空位，該圖片也會儲存為附件。",
                "촬영하거나 사진을 선택하면 비용 이름, 금액, 날짜를 인식합니다. 여유가 있으면 첨부 사진에도 저장됩니다.",
                "Haz o elige una foto para leer el nombre, el importe y la fecha. Si hay espacio, también se guarda como adjunto.",
                "Tire ou escolha uma foto para ler o nome, o valor e a data. Se houver espaço, ela também será salva como anexo."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)

            if isScanning {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(text(
                        "レシートを読み取り中…", "Scanning receipt…",
                        "正在识别收据…", "正在辨識收據…", "영수증 인식 중…",
                        "Leyendo recibo…", "Lendo recibo…"
                    ))
                }
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                HStack(spacing: 10) {
                    Button {
                        dismissKeyboard()
                        DispatchQueue.main.async { openCamera() }
                    } label: {
                        actionLabel(
                            text(
                                "撮影して読み取る", "Scan with Camera",
                                "拍摄并识别", "拍攝並辨識", "촬영해서 인식",
                                "Escanear con cámara", "Ler com a câmera"
                            ),
                            symbol: "camera.viewfinder"
                        )
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        actionLabel(
                            text(
                                "写真から読み取る", "Scan from Photos",
                                "从照片识别", "從照片辨識", "사진에서 인식",
                                "Leer desde fotos", "Ler das fotos"
                            ),
                            symbol: "photo.badge.magnifyingglass"
                        )
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { dismissKeyboard() })
                }
            }
        }
        .appCard()
        .onChange(of: pickerItem) { _, item in loadAndScan(item) }
        .sheet(item: $scanResult) { result in
            ReceiptOCRReviewView(result: result, currency: currency, onApply: onApply)
                .environmentObject(profileStore)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker { image in
                guard let data = image.jpegData(compressionQuality: 0.9) else { return }
                scan(data)
            }
            .ignoresSafeArea()
        }
        .alert(
            text(
                "カメラを使用できません", "Camera Unavailable",
                "无法使用相机", "無法使用相機", "카메라를 사용할 수 없습니다",
                "Cámara no disponible", "Câmera indisponível"
            ),
            isPresented: $showCameraUnavailable
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(text(
                "Simulatorではカメラを使用できません。実機のiPhoneで確認してください。",
                "The camera is unavailable in Simulator. Test this feature on a real iPhone.",
                "Simulator无法使用相机。请在真实的iPhone上进行测试。",
                "Simulator無法使用相機。請在實際的iPhone上測試。",
                "Simulator에서는 카메라를 사용할 수 없습니다. 실제 iPhone에서 테스트하세요.",
                "La cámara no está disponible en Simulator. Pruébala en un iPhone real.",
                "A câmera não está disponível no Simulator. Teste em um iPhone real."
            ))
        }
        .alert(
            text(
                "読み取れませんでした", "Could Not Scan Receipt",
                "无法识别", "無法辨識", "인식할 수 없습니다",
                "No se pudo leer", "Não foi possível ler"
            ),
            isPresented: errorBinding
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func actionLabel(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.subheadline.bold())
            .lineLimit(2)
            .minimumScaleFactor(0.75)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppTheme.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraUnavailable = true
            return
        }
        showCamera = true
    }

    private func loadAndScan(_ item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            defer { pickerItem = nil }
            guard let data = try? await item.loadTransferable(type: Data.self),
                  UIImage(data: data) != nil else {
                showScanError()
                return
            }
            scan(data)
        }
    }

    private func scan(_ data: Data) {
        guard !isScanning else { return }
        dismissKeyboard()

        if imageData.count < 3, !imageData.contains(data) {
            imageData.append(data)
        }

        isScanning = true
        Task {
            defer { isScanning = false }
            do {
                scanResult = try await Task.detached(priority: .userInitiated) {
                    try ReceiptOCRService.recognize(imageData: data, inputCurrency: currency)
                }.value
            } catch {
                showScanError()
            }
        }
    }

    private func showScanError() {
        errorMessage = text(
            "文字を認識できませんでした。レシート全体が明るく、まっすぐ写っている写真でもう一度試してください。",
            "No text was recognized. Try again with a bright, straight photo showing the whole receipt.",
            "未能识别文字。请使用明亮、端正且包含完整收据的照片重试。",
            "未能辨識文字。請使用明亮、端正且包含完整收據的照片重試。",
            "텍스트를 인식하지 못했습니다. 영수증 전체가 밝고 똑바로 보이는 사진으로 다시 시도하세요.",
            "No se reconoció texto. Prueba con una foto clara, recta y que muestre todo el recibo.",
            "Nenhum texto foi reconhecido. Tente uma foto clara, reta e com o recibo inteiro."
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func text(
        _ ja: String, _ en: String, _ zhHans: String, _ zhHant: String,
        _ ko: String, _ es: String, _ pt: String
    ) -> String {
        language.text(
            ja: ja, en: en, zhHans: zhHans, zhHant: zhHant,
            ko: ko, es: es, pt: pt
        )
    }
}
