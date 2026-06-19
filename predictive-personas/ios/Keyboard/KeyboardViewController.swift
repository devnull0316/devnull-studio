import UIKit
import PersonaEngine

/// The custom keyboard.
///
/// It is a deliberately compact romaji→hiragana IME. The only "smart" behaviour
/// is exactly this product's thesis:
///   • candidates come from the **active persona's** learned data
///   • you can switch persona live, from the keyboard, and the candidates change
///
/// Everything heavy (conversion, ranking, learning, persistence) lives in
/// `PersonaEngine`, imported unchanged from the cross-platform package.
final class KeyboardViewController: UIInputViewController {

    private let service = PersonaService()
    private var engine: PersonaEngine { service.engine }

    /// Romaji typed since the last commit, e.g. "suki".
    private var romajiBuffer = "" {
        didSet { refreshMarkedAndCandidates() }
    }
    /// The last surface committed, used for next-word prediction.
    private var lastCommitted: String?

    private let candidateBar = CandidateBar()
    private var personaButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        service.bootstrapIfEmpty()
        buildUI()
        updatePersonaButtonTitle()
        refreshMarkedAndCandidates()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // The app may have changed personas/data while we were gone.
        service.reload()
        updatePersonaButtonTitle()
        refreshMarkedAndCandidates()
    }

    // MARK: - UI construction

    private func buildUI() {
        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 6
        root.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
        ])

        candidateBar.onSelect = { [weak self] in self?.commit(surface: $0) }
        root.addArrangedSubview(candidateBar)

        for chars in KeyboardLayout.letterRows {
            root.addArrangedSubview(makeLetterRow(chars))
        }

        root.addArrangedSubview(makeBottomRow())
    }

    private func makeLetterRow(_ chars: [Character]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 4
        row.distribution = .fillEqually
        for ch in chars {
            let title = String(ch)
            row.addArrangedSubview(makeKey(title) { [weak self] in self?.type(title) })
        }
        return row
    }

    private func makeBottomRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 6

        let globe = makeKey("🌐") { [weak self] in self?.advanceToNextInputMode() }
        globe.setContentHuggingPriority(.required, for: .horizontal)

        personaButton = makeKey("👤") { [weak self] in self?.cyclePersona() }
        personaButton.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let space = makeKey("空白") { [weak self] in self?.tapSpace() }
        space.widthAnchor.constraint(greaterThanOrEqualToConstant: 90).isActive = true

        let delete = makeKey("⌫") { [weak self] in self?.backspace() }
        let ret = makeKey("改行") { [weak self] in self?.tapReturn() }

        [globe, personaButton, space, delete, ret].forEach { row.addArrangedSubview($0) }
        return row
    }

    private func makeKey(_ title: String, action: @escaping () -> Void) -> UIButton {
        var config = UIButton.Configuration.gray()
        config.title = title
        config.baseForegroundColor = .label
        config.background.cornerRadius = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 6, bottom: 10, trailing: 6)
        let button = UIButton(configuration: config)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    // MARK: - Input handling

    private func type(_ letter: String) {
        romajiBuffer += letter.lowercased()
    }

    private func refreshMarkedAndCandidates() {
        // Show the in-progress conversion as marked (composing) text.
        let (hira, pending) = RomajiConverter.convert(romajiBuffer)
        let marked = hira + pending
        let length = (marked as NSString).length
        textDocumentProxy.setMarkedText(marked, selectedRange: NSRange(location: length, length: 0))

        // Candidates for whatever has resolved so far, from the active persona.
        var candidates = romajiBuffer.isEmpty ? [] : engine.complete(reading: romajiBuffer, limit: 8)
        // Always let the user commit the raw kana itself as the first option.
        if !marked.isEmpty && !candidates.contains(marked) {
            candidates.insert(marked, at: 0)
        }
        candidateBar.setCandidates(candidates)
    }

    private func commit(surface: String) {
        let reading = RomajiConverter.toHiragana(romajiBuffer)
        textDocumentProxy.unmarkText()
        textDocumentProxy.insertText(surface)

        // Learn on the active persona, then persist so the app + next launch see it.
        if !reading.isEmpty {
            try? engine.learn(reading: reading, surface: surface, previous: lastCommitted)
            try? service.persist()
        }
        lastCommitted = surface
        romajiBuffer = ""          // triggers refresh (marked cleared)
        showNextWordPredictions()
    }

    private func showNextWordPredictions() {
        guard let prev = lastCommitted else { return }
        let next = engine.predictNext(after: prev, limit: 8)
        if !next.isEmpty { candidateBar.setCandidates(next) }
    }

    private func tapSpace() {
        if !romajiBuffer.isEmpty, let top = candidateBar.firstCandidate {
            commit(surface: top)            // space commits the top candidate, IME-style
            return
        }
        textDocumentProxy.insertText(" ")
        lastCommitted = nil
    }

    private func backspace() {
        if !romajiBuffer.isEmpty {
            romajiBuffer.removeLast()        // triggers refresh
        } else {
            textDocumentProxy.deleteBackward()
        }
    }

    private func tapReturn() {
        if !romajiBuffer.isEmpty, let top = candidateBar.firstCandidate {
            commit(surface: top)
            return
        }
        textDocumentProxy.insertText("\n")
        lastCommitted = nil
    }

    // MARK: - Persona switching (the thesis, live on the keyboard)

    private func cyclePersona() {
        let all = engine.personas
        guard all.count > 1,
              let current = engine.activePersonaID,
              let idx = all.firstIndex(where: { $0.id == current }) else {
            updatePersonaButtonTitle()
            return
        }
        let next = all[(idx + 1) % all.count]
        try? engine.switchPersona(to: next.id)
        try? service.persist()
        updatePersonaButtonTitle()
        refreshMarkedAndCandidates()       // same buffer, new persona → new candidates
    }

    private func updatePersonaButtonTitle() {
        let name = engine.activePersona?.name ?? "—"
        personaButton.configuration?.title = "👤 \(name)"
    }
}
