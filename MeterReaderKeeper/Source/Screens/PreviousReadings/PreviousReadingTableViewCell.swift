//
//  PreviousReadingTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//  Updated to use domain models on 8/26/26.
//

import UIKit

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
    
    private lazy var leftStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [readingMeterLabel, readingLocationLabel])
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

    var reading = MRKReading(id: UUID(), date: Date(), kWh: 0, meterID: UUID())
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
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
    
    func setup(reading: MRKReading, meterName: String, locationString: String) {
        self.reading = reading
        readingValueLabel.text = reading.formattedValue
        readingDateLabel.text = reading.formattedDate
        readingMeterLabel.text = meterName
        readingLocationLabel.text = locationString
    }
}
