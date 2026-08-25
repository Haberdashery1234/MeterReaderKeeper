//
//  HomeViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/2/21.
//  Refactored to programmatic UI on 8/25/26.
//

import UIKit

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "gauge.medium")
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Meter Reader Keeper"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Manage building meters and readings"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var takeReadingsButton: UIButton = {
        let button = createStyledButton(
            title: "Take Readings",
            backgroundColor: .systemBlue,
            action: #selector(takeReadingsTapped)
        )
        return button
    }()
    
    private lazy var previousReadingsButton: UIButton = {
        let button = createStyledButton(
            title: "Previous Readings",
            backgroundColor: .systemGreen,
            action: #selector(previousReadingsTapped)
        )
        return button
    }()
    
    private lazy var manageButton: UIButton = {
        let button = createStyledButton(
            title: "Manage Buildings & Meters",
            backgroundColor: .systemOrange,
            action: #selector(manageTapped)
        )
        return button
    }()
    
    private lazy var exportButton: UIButton = {
        let button = createStyledButton(
            title: "Export Data",
            backgroundColor: .systemPurple,
            action: #selector(exportDataTapped)
        )
        return button
    }()
    
    private lazy var seedDataButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Seed Test Data", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        button.setTitleColor(.systemGray, for: .normal)
        button.addTarget(self, action: #selector(seedDataTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(logoImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(buttonStackView)
        contentView.addSubview(seedDataButton)
        
        buttonStackView.addArrangedSubview(takeReadingsButton)
        buttonStackView.addArrangedSubview(previousReadingsButton)
        buttonStackView.addArrangedSubview(manageButton)
        buttonStackView.addArrangedSubview(exportButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
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
            
            // Logo
            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            logoImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Button Stack
            buttonStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 240), // 4 buttons * 56 height + 3 * 16 spacing
            
            // Seed Data Button
            seedDataButton.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 32),
            seedDataButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            seedDataButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            // Button heights
            takeReadingsButton.heightAnchor.constraint(equalToConstant: 56),
            previousReadingsButton.heightAnchor.constraint(equalToConstant: 56),
            manageButton.heightAnchor.constraint(equalToConstant: 56),
            exportButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }
    
    private func createStyledButton(title: String, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = backgroundColor
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    // MARK: - Actions
    @objc private func takeReadingsTapped() {
        let buildings = MeterManager.shared.buildings
        
        if buildings.isEmpty {
            showAlert(
                title: "No Buildings",
                message: "Please add buildings and meters before taking readings."
            )
            return
        }
        
        if buildings.count == 1 {
            coordinator?.showReadings(for: buildings[0])
        } else {
            showBuildingPicker(for: .takeReadings)
        }
    }
    
    @objc private func previousReadingsTapped() {
        coordinator?.showPreviousReadings()
    }
    
    @objc private func manageTapped() {
        coordinator?.showManagement()
    }
    
    @objc private func exportDataTapped() {
        let loadingAlert = UIAlertController(title: nil, message: "Exporting data...", preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        loadingAlert.view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            spinner.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20)
        ])
        present(loadingAlert, animated: true)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            MeterManager.shared.saveDataToPlist()
            
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    self?.sendPlist()
                }
            }
        }
    }
    
    @objc private func seedDataTapped() {
        let buildingCount = MeterManager.shared.buildings.count
        
        if buildingCount == 0 {
            DataSeeder.shared.seedData()
            showAlert(title: "Success", message: "Test data has been seeded successfully.")
        } else {
            DataSeeder.shared.seedMoreReadings()
            showAlert(title: "Success", message: "Additional readings have been added successfully.")
        }
    }
    
    // MARK: - Private Methods
    private func sendPlist() {
        let exportURL = MeterManager.shared.exportURL
        
        do {
            let plistData = try Data(contentsOf: exportURL)
            
            EmailService.shared.sendExport(from: self, plistData: plistData) { [weak self] result, error in
                if result == .failed {
                    self?.showAlert(title: "Send Failed", message: "Failed to send email. Please try again.")
                }
            }
            
        } catch {
            showAlert(title: "Export Failed", message: "Failed to export data. Please try again.")
        }
    }
    
    private func showBuildingPicker(for action: BuildingAction) {
        let alert = UIAlertController(title: "Select Building", message: nil, preferredStyle: .actionSheet)
        
        for building in MeterManager.shared.buildings {
            alert.addAction(UIAlertAction(title: building.name, style: .default) { [weak self] _ in
                switch action {
                case .takeReadings:
                    self?.coordinator?.showReadings(for: building)
                }
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = takeReadingsButton
            popover.sourceRect = takeReadingsButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Helper Types
    private enum BuildingAction {
        case takeReadings
    }
}
