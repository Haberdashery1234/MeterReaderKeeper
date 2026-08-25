//
//  ReadingMeterTableViewCell.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//

import UIKit

class ReadingMeterTableViewCell: UITableViewCell {

    // MARK: - UI Components
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
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

    var meter = Meter()
    var reading: Reading?
    
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
    
    func setup(withMeter meter: Meter) {
        readingDoneCheckImageView.isHidden = true
        self.meter = meter
        nameLabel.text = meter.name
        
        let floorNumber = meter.floor.number
        locationLabel.text = "Floor \(floorNumber)"
        
        let meterReadings = meter.meterReadings
        let date = Calendar.current.startOfDay(for: Date())
        let todaysReadings = meterReadings.filter { (reading) -> Bool in
            return reading.date == date
        }
        
        if todaysReadings.count > 0 {
            reading = todaysReadings[0]
            readingMade()
        }
    }
    
    func readingMade() {
        // update cell for readings
        readingDoneCheckImageView.isHidden = false
    }
}
