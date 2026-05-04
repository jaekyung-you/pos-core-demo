import SwiftUI
import DesignSystem
import CoreImage.CIFilterBuiltins

struct QRPaymentSheet: View {
    let amount: Int
    let onConfirm: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirming = false

    var body: some View {
        NavigationStack {
            VStack(spacing: TDS.Spacing.xxxl) {
                VStack(spacing: TDS.Spacing.lg) {
                    qrImage
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(TDS.Spacing.lg)
                        .background(TDS.Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.card))
                        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)

                    VStack(spacing: TDS.Spacing.xs) {
                        Text("결제 금액")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(TDS.Color.gray400)
                        Text("₩\(amount.formatted())")
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundColor(TDS.Color.gray900)
                    }
                }

                Text("고객이 QR코드를 스캔하면\n결제 확인 버튼을 눌러주세요")
                    .font(.system(size: 14))
                    .foregroundColor(TDS.Color.gray400)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Button {
                    isConfirming = true
                    Task {
                        await onConfirm()
                        dismiss()
                    }
                } label: {
                    HStack(spacing: TDS.Spacing.sm) {
                        if isConfirming {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.8)
                            Text("처리 중...")
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("결제 확인")
                        }
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(isConfirming ? TDS.Color.gray400 : TDS.Color.blue500)
                    .clipShape(RoundedRectangle(cornerRadius: TDS.Radius.button))
                }
                .disabled(isConfirming)
                .padding(.horizontal, TDS.Spacing.xl)
                .animation(.easeInOut(duration: 0.2), value: isConfirming)
            }
            .padding(TDS.Spacing.xxxl)
            .navigationTitle("QR 결제")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundColor(TDS.Color.gray400)
                        .disabled(isConfirming)
                }
            }
        }
    }

    private var qrImage: Image {
        let payload = "pos://pay?amount=\(amount)&method=qr&ts=\(Int(Date().timeIntervalSince1970))"
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"

        let context = CIContext()
        guard let output = filter.outputImage else { return Image(systemName: "qrcode") }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
            return Image(systemName: "qrcode")
        }
        return Image(uiImage: UIImage(cgImage: cgImage))
    }
}
