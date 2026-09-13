//
//  ReadingMeterTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//  Updated to use domain models on 8/26/26.
//

import UIKit

/// A Readings Main row: meter name and floor on the left, a green
/// checkmark on the right when a reading has already been recorded today.
class ReadingMeterTableViewCell: UITableViewCell {

    // MARK: - UI Components
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        AppStyle.applyScaledFont(to: label, size: 16, weight: .medium, relativeTo: .callout)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        AppStyle.applyScaledFont(to: label, size: 14, relativeTo: .footnote)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var readingDoneCheckImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, locationLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// The meter this row represents. Defaults to an empty placeholder
    /// until `setup(meter:floorNumber:)` is called.
    var meter = MRKMeter(id: UUID(), name: "", meterDescription: "", qrString: "", imageData: Data(), latestReadingDate: Date(), floorID: UUID(), readings: [])
    /// Today's reading for `meter`, if one exists — set by `setup(meter:floorNumber:)`.
    var reading: MRKReading?

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    /// Pins the name/location stack and the checkmark icon to the content view.
    private func setupUI() {
        contentView.addSubview(textStackView)
        contentView.addSubview(readingDoneCheckImageView)
        
        NSLayoutConstraint.activate([
            textStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStackView.trailingAnchor.constraint(equalTo: readingDoneCheckImageView.leadingAnchor, constant: -12),
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            readingDoneCheckImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            readingDoneCheckImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            readingDoneCheckImageView.widthAnchor.constraint(equalToConstant: 24),
            readingDoneCheckImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    /// Configures the cell's labels from a meter, and shows the checkmark
    /// if it already has a reading recorded today.
    ///
    /// - Parameters:
    ///   - meter: The meter this row represents.
    ///   - floorNumber: The meter's floor number, shown as "Floor N".
    func setup(meter: MRKMeter, floorNumber: Int16) {
        readingDoneCheckImageView.isHidden = true
        self.meter = meter
        nameLabel.text = meter.name
        locationLabel.text = "Floor \(floorNumber)"
        
        let date = Calendar.current.startOfDay(for: Date())
        let todaysReadings = meter.readings.filter { $0.date == date }
        
        if let todaysReading = todaysReadings.first {
            reading = todaysReading
            readingMade()
        } else {
            reading = nil
        }
    }
    
    /// Reveals the "reading done" checkmark.
    func readingMade() {
        readingDoneCheckImageView.isHidden = false
    }
}
