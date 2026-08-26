//
//  MeterTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class MeterTableViewCell: UITableViewCell {

    // MARK: - UI Components
    private lazy var meterImageView: UIImageView = {
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
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var textStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, locationLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    var meter = CoreDataMeter()
    
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
        contentView.addSubview(meterImageView)
        contentView.addSubview(textStackView)
        
        NSLayoutConstraint.activate([
            meterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            meterImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            meterImageView.widthAnchor.constraint(equalToConstant: 40),
            meterImageView.heightAnchor.constraint(equalToConstant: 40),
            
            textStackView.leadingAnchor.constraint(equalTo: meterImageView.trailingAnchor, constant: 12),
            textStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func setup(withMeter meter: CoreDataMeter) {
        self.meter = meter
        nameLabel.text = meter.name
        let floor = meter.floor
        locationLabel.text =  "\(floor.building.name) - Floor \(floor.number)"
        meterImageView.image = UIImage(data: meter.image)
    }
}
