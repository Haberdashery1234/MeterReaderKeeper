//
//  FloorTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class FloorTableViewCell: UITableViewCell {

    // MARK: - UI Components
    private lazy var floorMapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var metersLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, metersLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    var floor = Floor()
    
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
        contentView.addSubview(floorMapImageView)
        contentView.addSubview(textStackView)
        
        NSLayoutConstraint.activate([
            floorMapImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            floorMapImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            floorMapImageView.widthAnchor.constraint(equalToConstant: 40),
            floorMapImageView.heightAnchor.constraint(equalToConstant: 40),
            
            textStackView.leadingAnchor.constraint(equalTo: floorMapImageView.trailingAnchor, constant: 12),
            textStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func setup(withFloor floor: Floor) {
        self.floor = floor
        let nameString = "\(floor.building.name) - Floor \(floor.number)"
        nameLabel.text = nameString
        metersLabel.text = "\(floor.floorMeters.count) Meters"
        floorMapImageView.image = UIImage(data: floor.map)
    }
}
