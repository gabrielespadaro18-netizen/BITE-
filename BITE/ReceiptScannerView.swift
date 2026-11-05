import SwiftUI
import PhotosUI
import Vision
import UIKit

struct ReceiptScannerView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var photo: PhotosPickerItem?
    @State private var cameraPresented = false
    @State private var cameraData: Data?
    @State private var candidates: [ReceiptCandidate] = []
    @State private var processing = false
    @State private var errorMessage: String?
    @State private var didScan = false

    private var hasSelection: Bool {
        candidates.contains { $0.selected && !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("Scan a receipt")
                    .font(.system(size: 25, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Choose a photo or take one. Check the recognized foods before adding them to your pantry.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 12) {
                    PhotosPicker(selection: $photo, matching: .images) {
                        Label("Photo library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity).frame(height: 48)
                    }
                    .buttonStyle(.bordered)
                    Button { cameraPresented = true } label: {
                        Label("Camera", systemImage: "camera")
                            .frame(maxWidth: .infinity).frame(height: 48)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                }
                .tint(Color.biteGreen)

                if processing {
                    Spacer()
                    ProgressView("Reading receipt...")
                    Spacer()
                } else if candidates.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        didScan ? "No products recognized" : "Ready to scan",
                        systemImage: "doc.text.viewfinder",
                        description: Text(didScan ? "Try a clearer, well-lit photo or enter items manually." : "The recognition runs on your iPhone. No receipt images are sent to Airtable."))
                    Spacer()
                } else {
                    Text("Recognized items · edit, deselect, or correct quantities")
                        .font(.footnote).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    List {
                        ForEach($candidates) { $item in
                            HStack(spacing: 10) {
                                Toggle("Include food", isOn: $item.selected)
                                    .labelsHidden().tint(Color.biteGreen)
                                VStack(alignment: .leading, spacing: 6) {
                                    TextField("Food name", text: $item.name)
                                        .textInputAutocapitalization(.words)
                                    Stepper("Qty: \(item.quantity)", value: $item.quantity, in: 1...99)
                                        .font(.caption)
                                }
                            }
                        }
                        .onDelete { candidates.remove(atOffsets: $0) }
                    }
                    .listStyle(.plain)
                }
                PrimaryButton(title: "Add selected foods", enabled: hasSelection && !processing) {
                    for item in candidates where item.selected {
                        app.addPantry(name: item.name, amount: item.quantity, expiry: nil)
                    }
                    dismiss()
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } }
            }
            .fullScreenCover(isPresented: $cameraPresented) {
                ReceiptCamera(imageData: $cameraData)
                    .ignoresSafeArea()
            }
            .onChange(of: cameraData) { _, newValue in
                if let newValue { Task { await recognize(newValue) } }
            }
            .onChange(of: photo) { _, selected in
                guard let selected else { return }
                Task {
                    do {
                        if let data = try await selected.loadTransferable(type: Data.self) {
                            await recognize(data)
                        } else { errorMessage = "Unable to read the selected image." }
                    } catch { errorMessage = error.localizedDescription }
                }
            }
            .alert("Receipt scan failed", isPresented: Binding(get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "Try again") }
        }
    }

    @MainActor private func recognize(_ data: Data) async {
        processing = true
        defer { processing = false }
        do {
            let strings = try await Task.detached(priority: .userInitiated) {
                try ReceiptTextRecognition.extract(data: data)
            }.value
            candidates = ReceiptParser.parse(strings)
            didScan = true
        } catch { errorMessage = error.localizedDescription }
    }
}

private enum ReceiptTextRecognition {
    static func extract(data: Data) throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["it-IT", "en-US"]
        let handler = VNImageRequestHandler(data: data, options: [:])
        try handler.perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
    }
}

/// UIKit bridge is used only because PhotosPicker does not provide a live camera capture UI.
private struct ReceiptCamera: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var imageData: Data?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ReceiptCamera
        init(parent: ReceiptCamera) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.imageData = image.jpegData(compressionQuality: 0.85) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
