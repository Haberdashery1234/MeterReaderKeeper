//
//  PreviousReadingTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//  Updated to use domain models on 8/26/26.
//

import UIKit

/// A Previous Readings row: meter name/location and reading count on the
/// left, the most recent matching reading's value/date on the right. One
/// row represents a whole meter, not a single reading — see
/// `PreviousReadingsViewModel.MeterReadingSummary`.
class PreviousReadingTableViewCell: UITableViewCell {

    // MARK: - UI Components
    private lazy var readingMeterLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var readingLocationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var readingValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var readingDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var readingCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var leftStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [readingMeterLabel, readingLocationLabel, readingCountLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var rightStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [readingValueLabel, readingDateLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .trailing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup

    /// Pins the left (name/location/count) and right (value/date) stacks
    /// to the content view.
    private func setupUI() {
        contentView.addSubview(leftStackView)
        contentView.addSubview(rightStackView)
        
        NSLayoutConstraint.activate([
            leftStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leftStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            leftStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            leftStackView.trailingAnchor.constraint(lessThanOrEqualTo: rightStackView.leadingAnchor, constant: -12),
            
            rightStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rightStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        // Set content hugging/compression for proper layout
        leftStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rightStackView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    /// Configures the cell's labels from one meter's reading summary.
    ///
    /// - Parameter summary: The meter, its location, and its most recent
    ///   matching reading.
    func setup(summary: PreviousReadingsViewModel.MeterReadingSummary) {
        readingMeterLabel.text = summary.meterName
        readingLocationLabel.text = summary.location
        readingCountLabel.text = summary.readingCountText
        readingValueLabel.text = summary.formattedLastReadingValue
        readingDateLabel.text = summary.formattedLastReadingDate
    }
}
