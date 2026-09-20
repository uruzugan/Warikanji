import SwiftUI
import PhotosUI
import UIKit

struct ReceiptPhotoPickerCard: View {
    @EnvironmentObject private var profileStore: ProfileStore
    @Binding var imageData: [Data]

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var previewIndex: Int?

    private var language: AppLanguage { profileStore.activeLanguage }
    private var remainingCount: Int { max(0, 3 - imageData.count) }

    private var title: String {
        language.text(
            ja: "レシート写真", en: "Receipt Photos",
            zhHans: "收据照片", zhHant: "收據照片",
            ko: "영수증 사진", es: "Fotos del recibo", pt: "Fotos do recibo"
        )
    }

    private var addText: String {
        language.text(
            ja: "写真を追加", en: "Add Photo",
            zhHans: "添加照片", zhHant: "新增照片",
            ko: "사진 추가", es: "Añadir foto", pt: "Adicionar foto"
        )
    }

    private var helpText: String {
        language.text(
            ja: "最大3枚まで保存できます。写真をタップすると拡大できます。",
            en: "Save up to 3 photos. Tap a photo to enlarge it.",
            zhHans: "最多可保存3张照片。点击照片可放大查看。",
            zhHant: "最多可儲存3張照片。點擊照片可放大查看。",
            ko: "최대 3장까지 저장할 수 있습니다. 사진을 탭하면 확대할 수 있습니다.",
            es: "Puedes guardar hasta 3 fotos. Toca una foto para ampliarla.",
            pt: "Você pode salvar até 3 fotos. Toque em uma foto para ampliá-la."
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
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: remainingCount,
                    matching: .images
                ) {
                    Label(addText, systemImage: "photo.badge.plus")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(AppTheme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            Text(helpText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .appCard()
        .onChange(of: pickerItems) { _, items in
            load(items)
        }
        .sheet(isPresented: previewBinding) {
            receiptPreview
        }
    }

    @ViewBuilder
    private func preview(_ data: Data, index: Int) -> some View {
        if let image = UIImage(data: data) {
            ZStack(alignment: .topTrailing) {
                Button {
                    previewIndex = index
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button {
                    imageData.remove(at: index)
                    if previewIndex == index { previewIndex = nil }
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
    private var receiptPreview: some View {
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
}
