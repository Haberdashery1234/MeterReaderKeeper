//
//  BuildingTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//  Updated to use domain models on 8/26/26.
//

import UIKit

/// A Management "Buildings" segment row: building name, floor count, and
/// meter count, stacked vertically and self-sizing.
class BuildingTableViewCell: UITableViewCell {

    // MARK: - UI Components
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        AppStyle.applyScaledFont(to: label, size: 17, weight: .semibold, relativeTo: .headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isAccessibilityElement = false
        return label
    }()
    
    private lazy var floorsLabel: UILabel = {
        let label = UILabel()
        AppStyle.applyScaledFont(to: label, size: 14, relativeTo: .footnote)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isAccessibilityElement = false
        return label
    }()
    
    private lazy var metersLabel: UILabel = {
        let label = UILabel()
        AppStyle.applyScaledFont(to: label, size: 14, relativeTo: .footnote)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isAccessibilityElement = false
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, floorsLabel, metersLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    /// The building this row represents. Defaults to an empty placeholder
    /// until `setup(withBuilding:)` is called.
    var building = MRKBuilding(id: UUID(), name: "", floors: [])

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    /// Pins the name/floors/meters stack to the content view's top and
    /// bottom (not centered), so the cell self-sizes via
    /// `UITableView.automaticDimension`.
    private func setupUI() {
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    /// Configures the cell's labels from a building.
    func setup(withBuilding building: MRKBuilding) {
        self.building = building
        nameLabel.text = building.name
        floorsLabel.text = "\(building.floors.count) Floors"
        metersLabel.text = "\(building.totalMeterCount) Meters"

        // Combine the row's separate labels into one VoiceOver
        // announcement (name/floors/meters subviews are all
        // `isAccessibilityElement = false` above).
        isAccessibilityElement = true
        accessibilityLabel = building.name
        accessibilityValue = "\(building.floors.count) floors, \(building.totalMeterCount) meters"
    }
}
