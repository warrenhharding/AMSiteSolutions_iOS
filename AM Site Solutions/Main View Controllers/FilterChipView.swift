//
//  FilterChipView.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 06/08/2025.
//

import UIKit

protocol FilterChipViewDelegate: AnyObject {
    func didSelectFilter(_ filter: String)
}

class FilterChipView: UIView {
    weak var delegate: FilterChipViewDelegate?
    private var chips: [UIButton] = []
    private var selectedFilter: String = "All Machines"

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)

        // Make the scroll view fill the entire FilterChipView
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Pin the stack view to the edges of the scroll view's content area
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            
            // Ensure the stack view's height matches the scroll view's frame height
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        let filters = ["All Machines", "Active", "Inactive", "Under Repair"]
        
        for (index, filter) in filters.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(filter, for: .normal)
            button.layer.cornerRadius = 15
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            
            // Ensure buttons don't get compressed
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            chips.append(button)
            stackView.addArrangedSubview(button)
        }
        
        // Set initial selection state
        updateSelectedChip(at: 0)
    }

    @objc private func chipTapped(_ sender: UIButton) {
        guard let index = chips.firstIndex(of: sender) else { return }
        selectedFilter = sender.titleLabel?.text ?? "All Machines"
        updateSelectedChip(at: index)
        delegate?.didSelectFilter(selectedFilter)
    }

    private func updateSelectedChip(at index: Int) {
        for (i, button) in chips.enumerated() {
            if i == index {
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
            } else {
                button.backgroundColor = .systemGray5
                button.setTitleColor(.systemBlue, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            }
        }
    }
}
