import SwiftUI
import PhotosUI
import UIKit

struct ReceiptPhotoPickerCard: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Binding var imageData: [Data]
    let currency: AppCurrency
    let onApplyOCR: (ReceiptOCRResult) -> Void

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var previewIndex: Int?
    @State private var showCamera = false
    @State private var showCameraUnavailable = false
    @State private var showOCRPhotoSelection = false
    @State private var isScanning = false
    @State private var scanResult: ReceiptOCRResult?
    @State private var scanErrorMessage: String?

    private var language: AppLanguage { profileStore.activeLanguage }
    private var remainingCount: Int { max(0, 3 - imageData.count) }

    private var title: String {
        language.text(
            ja: "写真", en: "Photos",
            zhHans: "照片", zhHant: "照片",
            ko: "사진", es: "Fotos", pt: "Fotos"
        )
    }

    private var libraryText: String {
        language.text(
            ja: "写真を選ぶ", en: "Choose Photos",
            zhHans: "选择照片", zhHant: "選擇照片",
            ko: "사진 선택", es: "Elegir fotos", pt: "Escolher fotos"
        )
    }

    private var cameraText: String {
        language.text(
            ja: "カメラで撮る", en: "Take Photo",
            zhHans: "拍摄照片", zhHant: "拍攝照片",
            ko: "사진 촬영", es: "Tomar foto", pt: "Tirar foto"
        )
    }

    private var helpText: String {
        language.text(
            ja: "レシートなどの写真を最大3枚まで保存できます。写真をタップすると拡大できます。",
            en: "Save up to 3 photos, such as receipts. Tap a photo to enlarge it.",
            zhHans: "最多可保存3张收据等照片。点击照片可放大查看。",
            zhHant: "最多可儲存3張收據等照片。點擊照片可放大查看。",
            ko: "영수증 등의 사진을 최대 3장까지 저장할 수 있습니다. 사진을 탭하면 확대됩니다.",
            es: "Puedes guardar hasta 3 fotos, como recibos. Toca una foto para ampliarla.",
            pt: "Você pode salvar até 3 fotos, como recibos. Toque em uma foto para ampliá-la."
        )
    }

    private var scanText: String {
        language.text(
            ja: "写真からレシートを読み取る", en: "Scan Receipt from Photo",
            zhHans: "从照片识别收据", zhHant: "從照片辨識收據",
            ko: "사진에서 영수증 인식", es: "Leer recibo de la foto",
            pt: "Ler recibo da foto"
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "camera.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.primary)

            if !imageData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(imageData.indices, id: \.self) { index in
                            preview(imageData[index], index: index)
                        }
                    }
                }
            }

            if remainingCount > 0 {
                HStack(spacing: 10) {
                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: remainingCount,
                        matching: .images
                    ) {
                        Label(libraryText, systemImage: "photo.on.rectangle")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(AppTheme.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { dismissKeyboard() })

                    Button {
                        dismissKeyboard()
                        DispatchQueue.main.async { openCamera() }
                    } label: {
                        Label(cameraText, systemImage: "camera.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(AppTheme.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }

            if !imageData.isEmpty {
                Button(action: choosePhotoToScan) {
                    Group {
                        if isScanning {
                            HStack {
                                ProgressView()
                                Text(language.text(
                                    ja: "読み取り中…", en: "Scanning…",
                                    zhHans: "识别中…", zhHant: "辨識中…",
                                    ko: "인식 중…", es: "Leyendo…", pt: "Lendo…"
                                ))
                            }
                        } else {
                            Label(scanText, systemImage: "doc.text.viewfinder")
                        }
                    }
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(AppTheme.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(isScanning)
            }

            Text(helpText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .appCard()
        .onChange(of: pickerItems) { _, items in
            load(items)
        }
        .sheet(isPresented: previewBinding) { photoPreview }
        .sheet(item: $scanResult) { result in
            ReceiptOCRReviewView(
                result: result,
                currency: currency,
                onApply: onApplyOCR
            )
            .environmentObject(profileStore)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker { image in addCameraImage(image) }
                .ignoresSafeArea()
        }
        .alert(
            language.text(
                ja: "カメラを使用できません", en: "Camera Unavailable",
                zhHans: "无法使用相机", zhHant: "無法使用相機",
                ko: "카메라를 사용할 수 없습니다",
                es: "Cámara no disponible", pt: "Câmera indisponível"
            ),
            isPresented: $showCameraUnavailable
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(language.text(
                ja: "Simulatorではカメラを使用できません。実機のiPhoneで確認してください。",
                en: "The camera is unavailable in Simulator. Test this feature on a real iPhone.",
                zhHans: "Simulator无法使用相机。请在真实的iPhone上进行测试。",
                zhHant: "Simulator無法使用相機。請在實際的iPhone上測試。",
                ko: "Simulator에서는 카메라를 사용할 수 없습니다. 실제 iPhone에서 테스트하세요.",
                es: "La cámara no está disponible en Simulator. Pruébala en un iPhone real.",
                pt: "A câmera não está disponível no Simulator. Teste em um iPhone real."
            ))
        }
        .confirmationDialog(
            language.text(
                ja: "読み取る写真を選択", en: "Choose a Photo to Scan",
                zhHans: "选择要识别的照片", zhHant: "選擇要辨識的照片",
                ko: "인식할 사진 선택", es: "Elige una foto", pt: "Escolha uma foto"
            ),
            isPresented: $showOCRPhotoSelection,
            titleVisibility: .visible
        ) {
            ForEach(imageData.indices, id: \.self) { index in
                Button(photoLabel(index)) { scanPhoto(at: index) }
            }
            Button(language.t(.cancel), role: .cancel) {}
        }
        .alert(
            language.text(
                ja: "読み取れませんでした", en: "Could Not Scan Receipt",
                zhHans: "无法识别", zhHant: "無法辨識",
                ko: "인식할 수 없습니다", es: "No se pudo leer", pt: "Não foi possível ler"
            ),
            isPresented: scanErrorBinding
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(scanErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private func preview(_ data: Data, index: Int) -> some View {
        if let image = UIImage(data: data) {
            ZStack(alignment: .topTrailing) {
                Button {
                    dismissKeyboard()
                    DispatchQueue.main.async { previewIndex = index }
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button {
                    dismissKeyboard()
                    guard imageData.indices.contains(index) else { return }
                    imageData.remove(at: index)

                    if let previewIndex {
                        if previewIndex == index {
                            self.previewIndex = nil
                        } else if previewIndex > index {
                            self.previewIndex = previewIndex - 1
                        }
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .background(Circle().fill(.black.opacity(0.55)))
                }
                .padding(5)
            }
        }
    }

    private var previewBinding: Binding<Bool> {
        Binding(
            get: { previewIndex != nil },
            set: { if !$0 { previewIndex = nil } }
        )
    }

    @ViewBuilder
    private var photoPreview: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let index = previewIndex,
                   imageData.indices.contains(index),
                   let image = UIImage(data: imageData[index]) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(language.text(
                        ja: "閉じる", en: "Close",
                        zhHans: "关闭", zhHant: "關閉",
                        ko: "닫기", es: "Cerrar", pt: "Fechar"
                    )) {
                        previewIndex = nil
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraUnavailable = true
            return
        }

        showCamera = true
    }

    private func addCameraImage(_ image: UIImage) {
        guard imageData.count < 3,
              let data = image.jpegData(compressionQuality: 0.9) else { return }

        imageData.append(data)
    }

    private func choosePhotoToScan() {
        dismissKeyboard()
        guard imageData.count != 1 else {
            scanPhoto(at: 0)
            return
        }
        showOCRPhotoSelection = true
    }

    private func scanPhoto(at index: Int) {
        guard imageData.indices.contains(index), !isScanning else { return }
        let data = imageData[index]
        isScanning = true

        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try ReceiptOCRService.recognize(
                        imageData: data,
                        inputCurrency: currency
                    )
                }.value
                scanResult = result
            } catch {
                scanErrorMessage = language.text(
                    ja: "文字を認識できませんでした。レシート全体が明るく、まっすぐ写っている写真でもう一度試してください。",
                    en: "No text was recognized. Try again with a bright, straight photo showing the whole receipt.",
                    zhHans: "未能识别文字。请使用明亮、端正且包含完整收据的照片重试。",
                    zhHant: "未能辨識文字。請使用明亮、端正且包含完整收據的照片重試。",
                    ko: "텍스트를 인식하지 못했습니다. 영수증 전체가 밝고 똑바로 보이는 사진으로 다시 시도하세요.",
                    es: "No se reconoció texto. Prueba con una foto clara, recta y que muestre todo el recibo.",
                    pt: "Nenhum texto foi reconhecido. Tente uma foto clara, reta e com o recibo inteiro."
                )
            }
            isScanning = false
        }
    }

    private func photoLabel(_ index: Int) -> String {
        language.text(
            ja: "写真 \(index + 1)", en: "Photo \(index + 1)",
            zhHans: "照片 \(index + 1)", zhHant: "照片 \(index + 1)",
            ko: "사진 \(index + 1)", es: "Foto \(index + 1)", pt: "Foto \(index + 1)"
        )
    }

    private var scanErrorBinding: Binding<Bool> {
        Binding(
            get: { scanErrorMessage != nil },
            set: { if !$0 { scanErrorMessage = nil } }
        )
    }

    private func load(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        Task {
            var loaded: [Data] = []

            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   UIImage(data: data) != nil {
                    loaded.append(data)
                }
            }

            await MainActor.run {
                imageData.append(contentsOf: loaded.prefix(max(0, 3 - imageData.count)))
                pickerItems = []
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
