import UIKit

/// Horizontal, scrollable row of tappable candidates — the visible payoff of the
/// persona engine. Whatever the active persona predicts shows up here.
final class CandidateBar: UIScrollView {
    var onSelect: ((String) -> Void)?

    private let stack = UIStackView()
    private var candidates: [String] = []

    var firstCandidate: String? { candidates.first }

    override init(frame: CGRect) {
        super.init(frame: frame)
        showsHorizontalScrollIndicator = false
        stack.axis = .horizontal
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor, constant: -6),
            stack.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: frameLayoutGuide.heightAnchor),
            heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setCandidates(_ items: [String]) {
        candidates = items
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in items {
            stack.addArrangedSubview(makeChip(item))
        }
    }

    private func makeChip(_ title: String) -> UIButton {
        var config = UIButton.Configuration.gray()
        config.title = title
        config.baseForegroundColor = .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        config.background.cornerRadius = 8
        let button = UIButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in self?.onSelect?(title) }, for: .touchUpInside)
        return button
    }
}
