import SwiftUI
import PhotosUI
import UIKit

struct ReceiptPhotoPickerCard: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Binding var imageData: [Data]

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var previewIndex: Int?
    @State private var showCamera = false
    @State private var showCameraUnavailable = false

    private var language: AppLanguage { profileStore.activeLanguage }
    private var remainingCount: Int { max(0, 3 - imageData.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                text(
                    "添付写真", "Attached Photos", "附件照片", "附件照片",
                    "첨부 사진", "Fotos adjuntas", "Fotos anexadas"
                ),
                systemImage: "paperclip"
            )
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
                        actionLabel(
                            text(
                                "写真を選ぶ", "Choose Photos", "选择照片", "選擇照片",
                                "사진 선택", "Elegir fotos", "Escolher fotos"
                            ),
                            symbol: "photo.on.rectangle"
                        )
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded { dismissKeyboard() })

                    Button {
                        dismissKeyboard()
                        DispatchQueue.main.async { openCamera() }
                    } label: {
                        actionLabel(
                            text(
                                "写真を撮る", "Take Photo", "拍摄照片", "拍攝照片",
                                "사진 촬영", "Tomar foto", "Tirar foto"
                            ),
                            symbol: "camera.fill"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(text(
                "記録用の写真を最大3枚まで添付できます。レシートの読み取りは、画面上部の「レシートから費用を入力」を使ってください。",
                "Attach up to 3 photos for reference. To scan a receipt, use “Enter Expense from Receipt” at the top of the screen.",
                "最多可附加3张照片作为记录。要识别收据，请使用画面顶部的“从收据输入费用”。",
                "最多可附加3張照片作為記錄。要辨識收據，請使用畫面頂部的「從收據輸入費用」。",
                "기록용 사진을 최대 3장까지 첨부할 수 있습니다. 영수증 인식은 화면 상단의 ‘영수증으로 비용 입력’을 사용하세요.",
                "Adjunta hasta 3 fotos como referencia. Para leer un recibo, usa «Introducir gasto desde recibo» arriba.",
                "Anexe até 3 fotos como referência. Para ler um recibo, use “Inserir despesa pelo recibo” no topo."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .appCard()
        .onChange(of: pickerItems) { _, items in load(items) }
        .sheet(isPresented: previewBinding) { photoPreview }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker { image in addCameraImage(image) }
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
    }

    private func actionLabel(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.subheadline.bold())
            .lineLimit(2)
            .minimumScaleFactor(0.75)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(AppTheme.primary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
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
                    Button(text(
                        "閉じる", "Close", "关闭", "關閉",
                        "닫기", "Cerrar", "Fechar"
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
            imageData.append(contentsOf: loaded.prefix(max(0, 3 - imageData.count)))
            pickerItems = []
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
