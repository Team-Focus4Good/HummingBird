import SwiftUI
import PencilKit
import Speech
import AVFoundation

struct BraindumpWriteView: View {

    enum DumpMode: String, CaseIterable {
        case write = "Write"
        case draw = "Draw"
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore
    @Environment(CalmCentreStore.self) private var store
    @FocusState private var isEditorFocused: Bool

    @State private var selectedMode: DumpMode = .write
    @State private var text = ""
    @State private var canvasData = Data()
    @State private var hasDrawing = false
    @State private var showSavedPopup = false
    @State private var showDiscardConfirmation = false
    @State private var showNameAlert = false
    @State private var showPermissionAlert = false
    @State private var entryTitle = ""
    @State private var isCanvasActive = false
    @State private var clearTrigger = UUID()
    @State private var undoTrigger = UUID()

    // Speech-to-Text State
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var initialTextBeforeSpeech = ""
    @State private var isPulsing = false

    private var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canSave: Bool {
        hasText || hasDrawing
    }

    var body: some View {
        ZStack {
            editorContent
            if showSavedPopup { savedOverlay }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showSavedPopup)
        .navigationTitle("Braindump")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
        .hideTabBar()
        .alert("Name your dump", isPresented: $showNameAlert) {
            TextField("", text: $entryTitle)
            Button("Save") { performSave() }
                .tint(.primary)
            Button("Skip", role: .cancel) {
                entryTitle = ""
                performSave()
            }
                .tint(.primary)
        }
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                speechRecognizer.errorMessage = nil
            }
        } message: {
            Text(speechRecognizer.errorMessage ?? "Please enable Microphone and Speech Recognition in Settings so you can speak your feelings into Braindump.")
        }
        .confirmationDialog(
            "Discard this dump?",
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                stopDictation()
                isCanvasActive = false
                dismiss()
            }
            Button("Keep Writing", role: .cancel) {
                if selectedMode == .draw {
                    isCanvasActive = true
                }
            }
        } message: {
            Text("Your thoughts won't be saved. That's okay — the act of writing itself helps clear your mind.")
        }
        .onChange(of: speechRecognizer.transcript) { _, newTranscript in
            guard speechRecognizer.isListening, !newTranscript.isEmpty else { return }
            let trimmedBase = initialTextBeforeSpeech.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedBase.isEmpty {
                text = newTranscript
            } else {
                text = "\(trimmedBase) \(newTranscript)"
            }
        }
        .onChange(of: speechRecognizer.isListening) { _, listening in
            // When mic goes active, animate the pulse indicator
            isPulsing = listening
        }
        .onChange(of: speechRecognizer.errorMessage) { _, error in
            if error != nil {
                showPermissionAlert = true
            }
        }
        .onDisappear {
            stopDictation()
        }
    }

    // MARK: - Editor

    private var editorContent: some View {
        VStack(spacing: 12) {
            modePicker

            if selectedMode == .write {
                textEditorArea
            } else {
                drawingCanvasArea
            }
        }
        .background(AppTheme.appGradient.ignoresSafeArea())
    }

    private var modePicker: some View {
        Picker("Mode", selection: $selectedMode) {
            ForEach(DumpMode.allCases, id: \.self) { mode in
                Label(mode.rawValue, systemImage: mode == .write ? "pencil.line" : "hand.draw")
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, 8)
        .onChange(of: selectedMode) { _, newMode in
            if newMode == .write {
                isCanvasActive = false
                isEditorFocused = true
            } else {
                stopDictation()
                isEditorFocused = false
                isCanvasActive = true
            }
        }
    }

    private var textEditorArea: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .focused($isEditorFocused)
                    .scrollContentBackground(.hidden)
                    .font(.body)
                    .padding(16)

                if text.isEmpty && !speechRecognizer.isListening {
                    Text("Write freely or speak your thoughts…")
                        .font(.body)
                        .foregroundStyle(Color(.placeholderText))
                        .padding(.leading, 21)
                        .padding(.top, 24)
                        .allowsHitTesting(false)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )

            // Floating mic button — bottom right corner
            micButton
                .padding(16)
        }
        .padding(.horizontal)
        .padding(.bottom, 13)
    }

    private var micButton: some View {
        Button {
            if speechRecognizer.isListening {
                stopDictation()
            } else {
                startDictation()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(speechRecognizer.isListening ? Color.red : Color.accentColor)
                    .frame(width: 52, height: 52)
                    .shadow(color: (speechRecognizer.isListening ? Color.red : Color.accentColor).opacity(0.4), radius: 8, x: 0, y: 4)
                    .scaleEffect(speechRecognizer.isListening && isPulsing ? 1.12 : 1.0)
                    .animation(
                        speechRecognizer.isListening
                            ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                            : .default,
                        value: isPulsing
                    )

                Image(systemName: speechRecognizer.isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            if speechRecognizer.isListening { isPulsing = true }
        }
    }

    private var drawingCanvasArea: some View {
        BraindumpCanvasView(
            canvasData: $canvasData,
            hasDrawing: $hasDrawing,
            isActive: $isCanvasActive,
            clearTrigger: $clearTrigger,
            undoTrigger: $undoTrigger
        )
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom, 13)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                stopDictation()
                isCanvasActive = false
                if canSave {
                    showDiscardConfirmation = true
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
            }
        }

        if selectedMode == .draw && hasDrawing {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    undoTrigger = UUID()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                stopDictation()
                promptForName()
            } label: {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? Color.accentColor : Color(.placeholderText))
            }
            .disabled(!canSave)
        }
    }

    // MARK: - Saved Overlay

    private var savedOverlay: some View {
        ZStack {
            AppTheme.appGradient
                .ignoresSafeArea()
                .onTapGesture {
                    showSavedPopup = false
                    dismiss()
                }

            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.bounce, value: showSavedPopup)

                Text("Mind cleared!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Great job getting those thoughts out.\nYour mind feels lighter already.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("+ 10 Focus Points")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Button {
                    showSavedPopup = false
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.accentColor)
                        )
                }
                .padding(.top, 4)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Speech & Actions

    private func startDictation() {
        isEditorFocused = false
        initialTextBeforeSpeech = text
        speechRecognizer.transcript = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        // Run on MainActor so @Observable state changes reach SwiftUI
        Task { @MainActor in
            speechRecognizer.startListening()
        }
    }

    private func stopDictation() {
        guard speechRecognizer.isListening else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        speechRecognizer.stopListening()
    }

    // MARK: - Save

    private func promptForName() {
        guard hasText || hasDrawing else { return }
        stopDictation()
        isEditorFocused = false
        isCanvasActive = false
        entryTitle = ""
        showNameAlert = true
    }

    private func performSave() {
        stopDictation()
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = entryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let titleToSave: String? = trimmedTitle.isEmpty ? nil : trimmedTitle
        let drawingToSave: Data? = hasDrawing ? canvasData : nil
        let currentUserId = userStore.currentUser?.id ?? DummyData.currentUser.id

        Task {
            await store.addBrainDumpEntry(
                content: trimmedText,
                drawingData: drawingToSave,
                title: titleToSave,
                userId: currentUserId,
                folderId: nil
            )
        }
        showSavedPopup = true
    }
}

#Preview {
    NavigationStack {
        BraindumpWriteView()
            .environment(CalmCentreStore.shared)
    }
}
