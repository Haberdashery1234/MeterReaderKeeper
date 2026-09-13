//
//  FloorTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//  Updated to use domain models on 8/26/26.
//

import UIKit

/// A Management "Floors" segment row: the floor's map thumbnail, display
/// name, and meter count. Rows are grouped into sections by building, so
/// this cell doesn't repeat the building name — see `setup(floor:)`.
class FloorTableViewCell: UITableViewCell {

    // MARK: - UI Components
    private lazy var floorMapImageView: UIImageView = {
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
    
    private lazy var metersLabel: UILabel = {
        let label = UILabel()
        AppStyle.applyScaledFont(to: label, size: 13, relativeTo: .footnote)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isAccessibilityElement = false
        return label
    }()
    
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, metersLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    /// The floor this row represents. Defaults to an empty placeholder
    /// until `setup(floor:)` is called.
    var floor = MRKFloor(id: UUID(), number: 1, mapImageData: Data(), buildingID: UUID(), meters: [])

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    /// Lays out the map thumbnail beside the name/meters text stack.
    private func setupUI() {
        contentView.addSubview(floorMapImageView)
        contentView.addSubview(textStackView)
        
        NSLayoutConstraint.activate([
            floorMapImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            floorMapImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            floorMapImageView.widthAnchor.constraint(equalToConstant: 40),
            floorMapImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Pinned to the contentView's top AND bottom (not centered) so
            // the cell self-sizes via UITableView.automaticDimension,
            // matching Building/Meter cells (2026-08-28) instead of
            // relying on a guessed fixed row height.
            textStackView.leadingAnchor.constraint(equalTo: floorMapImageView.trailingAnchor, constant: 12),
            textStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    /// Configures the cell's labels and map thumbnail from a floor.
    ///
    /// `buildingName` was dropped from this cell's own label (2026-08-28)
    /// — Management's Floors segment now groups rows into one section per
    /// building with the building name as the section header, so repeating
    /// it on every row read as redundant clutter.
    func setup(floor: MRKFloor) {
        self.floor = floor
        nameLabel.text = floor.displayName
        metersLabel.text = "\(floor.meters.count) Meters"
        floorMapImageView.image = UIImage(data: floor.mapImageData)

        // Combine the row's separate labels into one VoiceOver
        // announcement (name/meters subviews are both
        // `isAccessibilityElement = false` above).
        isAccessibilityElement = true
        accessibilityLabel = floor.displayName
        accessibilityValue = "\(floor.meters.count) meters"
    }
}
