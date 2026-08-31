//
//  AddEditBuildingViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/3/21.
//  Refactored to programmatic UI on 8/25/26.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//  Thinned to use AddEditBuildingViewModel on 8/26/26.
//

import UIKit

/// Add/edit form for a single `MRKBuilding`. Reused for both creating a new
/// building and editing an existing one — `viewModel.isEditing` (based on
/// whether it was handed a building) decides the screen title, whether the
/// floor-count field is still editable, and whether the delete button is
/// shown at all. Pushed by `AppCoordinator.showBuildingDetails(_:)`.
class AddEditBuildingViewController: UIViewController {

    // MARK: - Properties
    /// Used to pop back to the previous screen after a successful save or delete.
    weak var coordinator: AppCoordinator?
    /// Supplies the form's initial values and validates/persists a save.
    var viewModel: AddEditBuildingViewModel!
    
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
        AppStyle.stylePaddedTextField(textField)
        textField.autocapitalizationType = .words
        textField.returnKeyType = .next
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "AddEditBuilding.nameTextField"
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
        AppStyle.stylePaddedTextField(textField)
        textField.keyboardType = .numberPad
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "AddEditBuilding.floorsTextField"
        return textField
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        AppStyle.styleAsPrimaryButton(button)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "AddEditBuilding.saveButton"
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete Building", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "AddEditBuilding.deleteButton"
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
    /// Adds the form's subviews, including the delete button only when
    /// `viewModel.isEditing` (there's nothing to delete for a new building).
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(nameTextField)
        contentView.addSubview(floorsLabel)
        contentView.addSubview(floorsTextField)
        contentView.addSubview(saveButton)
        
        if viewModel.isEditing {
            contentView.addSubview(deleteButton)
        }
    }
    
    /// Lays out the form. The delete button's constraints (and whether the
    /// save button instead anchors straight to the bottom) depend on
    /// `viewModel.isEditing`, mirroring the conditional subview in `setupUI()`.
    private func setupConstraints() {
        let deleteButtonConstraints: [NSLayoutConstraint]
        
        if viewModel.isEditing {
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
    
    /// Adds a tap-to-dismiss gesture so tapping outside a text field closes the keyboard.
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    /// Fills the form from `viewModel`'s initial values. `floorsTextField`
    /// is disabled by `viewModel.isFloorsFieldEnabled` when editing an
    /// existing building, since shrinking the floor count destructively
    /// removes floors (see `saveTapped()`/`floorRemovalWarning(floorsText:)`).
    private func populateData() {
        nameTextField.text = viewModel.initialNameText
        floorsTextField.text = viewModel.initialFloorsText
        floorsTextField.isEnabled = viewModel.isFloorsFieldEnabled
        title = viewModel.screenTitle
    }

    // MARK: - Actions
    /// Save button handler. When reducing the floor count would delete
    /// existing floors, confirms with the user first via
    /// `viewModel.floorRemovalWarning(floorsText:)` before calling `performSave()`.
    @objc private func saveTapped() {
        if let warning = viewModel.floorRemovalWarning(floorsText: floorsTextField.text) {
            let alert = UIAlertController(title: "Remove Floors?", message: warning, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
                self?.performSave()
            })
            present(alert, animated: true)
            return
        }

        performSave()
    }

    /// Validates and persists the form via `viewModel.save(nameText:floorsText:)`,
    /// then pops back on success. Validation failures surface as an alert
    /// via the field's `FormValidationError.title`/`.message`.
    private func performSave() {
        Task { @MainActor in
            do {
                _ = try await viewModel.save(nameText: nameTextField.text, floorsText: floorsTextField.text)
                navigationController?.popViewController(animated: true)
            } catch let error as FormValidationError {
                showAlert(title: error.title, message: error.message)
            } catch {
                showAlert(title: "Save Failed", message: error.localizedDescription)
            }
        }
    }

    /// Delete button handler. Confirms with the user (the alert message
    /// spells out that floors, meters, and readings cascade too) before
    /// calling `viewModel.delete()`.
    @objc private func deleteTapped() {
        guard let building = viewModel.building else {
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
            Task { @MainActor in
                do {
                    try await self.viewModel.delete()
                    self.navigationController?.popViewController(animated: true)
                } catch {
                    self.showAlert(title: "Delete Failed", message: error.localizedDescription)
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    /// Presents a single-button ("OK") informational alert.
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension AddEditBuildingViewController: UITextFieldDelegate {
    /// Advances focus from the name field to the floors field on Return;
    /// dismisses the keyboard from any other field.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            floorsTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    /// Restricts `floorsTextField` to digits only; other fields are unrestricted.
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
