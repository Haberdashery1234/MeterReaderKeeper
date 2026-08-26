//
//  AddEditBuildingViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/3/21.
//  Refactored to programmatic UI on 8/25/26.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//

import UIKit
import os.log

class AddEditBuildingViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var repository: MeterRepositoryProtocol!
    var building: MRKBuilding?
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MeterReaderKeeper", category: "AddEditBuildingVC")
    
    // MARK: - Constants
    private enum Validation {
        static let maxBuildingNameLength = 100
        static let minFloorCount: Int16 = 1
        static let maxFloorCount: Int16 = 200
    }
    
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
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Building Name"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter building name"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .words
        textField.returnKeyType = .next
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let floorsLabel: UILabel = {
        let label = UILabel()
        label.text = "Number of Floors"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var floorsTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter number of floors"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete Building", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupKeyboardHandling()
        populateData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(nameTextField)
        contentView.addSubview(floorsLabel)
        contentView.addSubview(floorsTextField)
        contentView.addSubview(saveButton)
        
        if building != nil {
            contentView.addSubview(deleteButton)
        }
    }
    
    private func setupConstraints() {
        let deleteButtonConstraints: [NSLayoutConstraint]
        
        if building != nil {
            deleteButtonConstraints = [
                deleteButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 20),
                deleteButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                deleteButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            ]
        } else {
            deleteButtonConstraints = [
                saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            ]
        }
        
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
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Name Text Field
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Floors Label
            floorsLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24),
            floorsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            floorsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Floors Text Field
            floorsTextField.topAnchor.constraint(equalTo: floorsLabel.bottomAnchor, constant: 8),
            floorsTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            floorsTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            floorsTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Save Button
            saveButton.topAnchor.constraint(equalTo: floorsTextField.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
        ] + deleteButtonConstraints)
    }
    
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func populateData() {
        if let building = building {
            nameTextField.text = building.name
            floorsTextField.text = "\(building.floors.count)"
            floorsTextField.isEnabled = false // Can't change floor count on existing building
            title = "Edit Building"
        } else {
            title = "Add Building"
        }
    }
    
    // MARK: - Actions
    @objc private func saveTapped() {
        // Validate input
        guard let validationResult = validateInput() else {
            return // Error alert already shown
        }
        
        let (buildingName, floorCount) = validationResult
        
        // Check for duplicate name (only when creating new or changing name)
        if building == nil || building?.name != buildingName {
            if isDuplicateName(buildingName) {
                showAlert(
                    title: "Duplicate Name",
                    message: "A building with the name '\(buildingName)' already exists. Please choose a different name."
                )
                return
            }
        }
        
        // Save building
        if building != nil {
            // Update existing building
            logger.warning("Editing buildings not yet implemented - creating new building instead")
            showAlert(
                title: "Not Implemented",
                message: "Editing existing buildings is not yet supported. Please delete and recreate the building."
            )
        } else {
            // Create new building
            let input = MRKBuildingInput(name: buildingName, numberOfFloors: floorCount, autoCreateFloors: true)
            do {
                let newBuilding = try repository.addBuilding(input)
                logger.info("Successfully created building: \(newBuilding.name)")
                navigationController?.popViewController(animated: true)
            } catch {
                logger.error("Failed to create building: \(buildingName) - \(error.localizedDescription)")
                showAlert(
                    title: "Save Failed",
                    message: error.localizedDescription
                )
            }
        }
    }
    
    @objc private func deleteTapped() {
        guard let building = building else {
            logger.warning("Delete tapped but no building to delete")
            return
        }
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Delete Building",
            message: "Are you sure you want to delete '\(building.name)'? This will also delete all floors, meters, and readings associated with this building.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            do {
                try self.repository.deleteBuilding(id: building.id)
                self.logger.info("Deleted building: \(building.name)")
                self.navigationController?.popViewController(animated: true)
            } catch {
                self.showAlert(title: "Delete Failed", message: error.localizedDescription)
            }
        })
        
        present(alert, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Validation
    
    private func validateInput() -> (name: String, floors: Int16)? {
        // Validate name
        guard let nameText = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !nameText.isEmpty else {
            showAlert(title: "Invalid Name", message: "Please enter a building name.")
            return nil
        }
        
        guard nameText.count <= Validation.maxBuildingNameLength else {
            showAlert(
                title: "Name Too Long",
                message: "Building name must be \(Validation.maxBuildingNameLength) characters or less."
            )
            return nil
        }
        
        // Validate floor count
        guard let floorsText = floorsTextField.text,
              let floorsInt = Int16(floorsText) else {
            showAlert(title: "Invalid Floor Count", message: "Please enter a valid number of floors.")
            return nil
        }
        
        guard floorsInt >= Validation.minFloorCount else {
            showAlert(
                title: "Invalid Floor Count",
                message: "Building must have at least \(Validation.minFloorCount) floor."
            )
            return nil
        }
        
        guard floorsInt <= Validation.maxFloorCount else {
            showAlert(
                title: "Too Many Floors",
                message: "Building cannot have more than \(Validation.maxFloorCount) floors."
            )
            return nil
        }
        
        return (nameText, floorsInt)
    }
    
    private func isDuplicateName(_ name: String) -> Bool {
        let buildings = (try? repository.getBuildings()) ?? []
        return buildings.contains { building in
            building.name.lowercased() == name.lowercased()
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension AddEditBuildingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            floorsTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == floorsTextField {
            // Only allow numbers
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: string)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return true
    }
}
