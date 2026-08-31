//
//  AddEditReadingViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/5/21.
//  Refactored to programmatic UI on 8/25/26.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//  Thinned to use AddEditReadingViewModel on 8/26/26.
//

import UIKit

/// Add/edit form for a single `MRKReading` on one meter. Shows the meter's
/// photo, its building/floor/description for context, and a single kWh
/// entry field. Reused for both recording a new reading and editing an
/// existing one — `viewModel.screenTitle`/`initialReadingText` reflect
/// which. Pushed from the Readings flow (`AppCoordinator.showAddReading`/
/// `showEditReading`).
class AddEditReadingViewController: UIViewController {

    // MARK: - Properties
    /// Used to pop back to the previous screen after a successful save.
    weak var coordinator: AppCoordinator?
    /// Supplies the meter/building/floor context, the form's initial values, and validates/persists a save.
    var viewModel: AddEditReadingViewModel!
    
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
        AppStyle.styleImageWell(imageView)
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
        AppStyle.stylePaddedTextField(textField)
        textField.keyboardType = .decimalPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "AddEditReading.readingTextField"
        return textField
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Reading", for: .normal)
        AppStyle.styleAsPrimaryButton(button)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "AddEditReading.saveButton"
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
        populateData()
    }
    
    // MARK: - Setup
    /// Adds the form's subviews.
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(meterImageView)
        contentView.addSubview(infoStackView)
        contentView.addSubview(readingTitleLabel)
        contentView.addSubview(readingTextField)
        contentView.addSubview(saveButton)
    }
    
    /// Lays out the form.
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
    
    /// Adds a tap-to-dismiss gesture so tapping outside the field closes
    /// the keyboard, without swallowing the tap itself
    /// (`cancelsTouchesInView = false`, so a tap still reaches whatever it landed on).
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    /// Fills the meter photo/context labels and the reading field from `viewModel`.
    private func populateData() {
        buildingNameLabel.text = viewModel.building.name
        floorLabel.text = "Floor \(viewModel.floor.number)"
        descriptionLabel.text = viewModel.meter.meterDescription
        meterImageView.image = UIImage(data: viewModel.meter.imageData)
        readingTextField.text = viewModel.initialReadingText
        title = viewModel.screenTitle

        print("Loaded meter: \(self.viewModel.meter.name)")
    }

    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    /// Save button handler. Validates and persists the reading via
    /// `viewModel.save(readingText:)`, then pops back on success.
    /// Validation failures surface as an alert via the
    /// `FormValidationError.title`/`.message`.
    @objc private func saveTapped() {
        Task { @MainActor in
            do {
                _ = try await viewModel.save(readingText: readingTextField.text)
                navigationController?.popViewController(animated: true)
            } catch let error as FormValidationError {
                showAlert(title: error.title, message: error.message)
            } catch {
                print("Failed to save reading: \(error.localizedDescription)")
                showAlert(title: "Save Failed", message: error.localizedDescription)
            }
        }
    }

    /// Presents a single-button ("OK") informational alert.
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
