//
//  MeterTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//  Updated to use domain models on 8/26/26.
//

import UIKit

/// A meter list row shared across Management's "Meters" segment and the
/// Floor Meters screen: the meter's photo thumbnail, name, a
/// caller-supplied location/description subtitle, and a last-reading
/// summary line (orange when overdue).
class MeterTableViewCell: UITableViewCell {

    // MARK: - UI Components
    private lazy var meterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isAccessibilityElement = false
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        AppStyle.applyScaledFont(to: label, size: 15, weight: .medium, relativeTo: .subheadline)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isAccessibilityElement = false
        return label
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        AppStyle.applyScaledFont(to: label, size: 13, relativeTo: .footnote)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isAccessibilityElement = false
        return label
    }()
    
    /// Last-reading summary, e.g. "Last read Aug 20, 2026" or "Never
    /// read" — added 2026-08-28 so a Manage row is useful for spotting
    /// overdue meters, not just identifying them. Colored orange when
    /// `MRKMeter.isStale` is true (same threshold as Home's "Needs
    /// Attention" list).
    private lazy var lastReadingLabel: UILabel = {
        let label = UILabel()
        AppStyle.applyScaledFont(to: label, size: 12, relativeTo: .caption1)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isAccessibilityElement = false
        return label
    }()
    
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, locationLabel, lastReadingLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// The meter this row represents. Defaults to an empty placeholder
    /// until `setup(meter:locationString:)` is called.
    var meter = MRKMeter(id: UUID(), name: "", meterDescription: "", qrString: "", imageData: Data(), latestReadingDate: Date(), floorID: UUID(), readings: [])

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    /// Lays out the photo thumbnail beside the name/location/last-reading
    /// text stack.
    private func setupUI() {
        contentView.addSubview(meterImageView)
        contentView.addSubview(textStackView)
        
        NSLayoutConstraint.activate([
            meterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            meterImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            meterImageView.widthAnchor.constraint(equalToConstant: 40),
            meterImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Pinned to the contentView's top AND bottom (not centered) so
            // the cell self-sizes via UITableView.automaticDimension — a
            // fixed row height here used to clip/overlap the third line
            // added 2026-08-28 (same bug shape as BuildingTableViewCell).
            textStackView.leadingAnchor.constraint(equalTo: meterImageView.trailingAnchor, constant: 12),
            textStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    /// Configures the cell's labels and photo thumbnail from a meter.
    ///
    /// - Parameters:
    ///   - meter: The meter this row represents.
    ///   - locationString: Caller-supplied subtitle text — Management's
    ///     Meters segment passes the floor name; Floor Meters passes the
    ///     meter's own description (falling back to the floor name).
    func setup(meter: MRKMeter, locationString: String) {
        self.meter = meter
        nameLabel.text = meter.name
        locationLabel.text = locationString
        meterImageView.image = UIImage(data: meter.imageData)
        lastReadingLabel.text = meter.lastReadingSummary
        lastReadingLabel.textColor = meter.isStale() ? .systemOrange : .secondaryLabel

        // Combine the row's separate labels into one VoiceOver
        // announcement instead of three (name, location, last-reading
        // subviews are all `isAccessibilityElement = false` above).
        isAccessibilityElement = true
        accessibilityLabel = meter.name
        accessibilityValue = "\(locationString). \(meter.lastReadingSummary)"
    }
}
