//
//  AddEditReadingViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//  Refactored to programmatic UI on 8/25/26.
//

import UIKit
import os.log

class AddEditReadingViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MeterReaderKeeper", category: "AddEditReadingVC")
    
    var meter: Meter?
    var reading: Reading?
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var meterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let buildingNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let floorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let readingTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Reading (kWh)"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var readingTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter reading value"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Reading", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var infoStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [buildingNameLabel, floorLabel, descriptionLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupKeyboardDismissal()
        loadData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(meterImageView)
        contentView.addSubview(infoStackView)
        contentView.addSubview(readingTitleLabel)
        contentView.addSubview(readingTextField)
        contentView.addSubview(saveButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Meter Image View
            meterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            meterImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            meterImageView.widthAnchor.constraint(equalToConstant: 200),
            meterImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Info Stack
            infoStackView.topAnchor.constraint(equalTo: meterImageView.bottomAnchor, constant: 24),
            infoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Reading Title Label
            readingTitleLabel.topAnchor.constraint(equalTo: infoStackView.bottomAnchor, constant: 32),
            readingTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            readingTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Reading TextField
            readingTextField.topAnchor.constraint(equalTo: readingTitleLabel.bottomAnchor, constant: 8),
            readingTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            readingTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            readingTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Save Button
            saveButton.topAnchor.constraint(equalTo: readingTextField.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func loadData() {
        guard let meter = meter else {
            logger.error("No meter provided to AddEditReadingViewController")
            return
        }
        
        let floor = meter.floor
        let building = floor.building
        
        buildingNameLabel.text = building.name
        floorLabel.text = "Floor \(floor.number)"
        descriptionLabel.text = meter.meterDescription
        meterImageView.image = UIImage(data: meter.image)
        
        if let reading = reading {
            readingTextField.text = String(format: "%.2f", reading.kWh)
            title = "Edit Reading"
        } else {
            title = "Add Reading"
        }
        
        logger.info("Loaded meter: \(meter.name)")
    }
    
    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func saveTapped() {
        guard let meterReadingString = readingTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !meterReadingString.isEmpty else {
            showAlert(title: "Missing Reading", message: "Please enter a reading value.")
            return
        }
        
        guard let meterReading = Double(meterReadingString) else {
            showAlert(title: "Invalid Reading", message: "Please enter a valid numeric value.")
            return
        }
        
        guard meterReading >= 0 else {
            showAlert(title: "Invalid Reading", message: "Reading value must be positive.")
            return
        }
        
        guard let meter = meter else {
            logger.error("Meter is nil when trying to save reading")
            return
        }
        
        if let reading = reading {
            MeterManager.shared.updateReading(reading, with: meterReading)
            logger.info("Updated reading: \(meterReading) kWh")
        } else {
            let date = Calendar.current.startOfDay(for: Date())
            MeterManager.shared.addReading(toMeter: meter, withKWH: meterReading, date: date)
            logger.info("Added new reading: \(meterReading) kWh for meter: \(meter.name)")
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

