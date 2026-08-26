//
//  AddEditMeterViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/2/21.
//  Refactored to programmatic UI on 8/25/26.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//

import UIKit
import os.log

class AddEditMeterViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var repository: MeterRepositoryProtocol!
    var meter: MRKMeter?
    var building: MRKBuilding?
    var floor: MRKFloor?
    
    private var buildings = [MRKBuilding]()
    private var floors = [MRKFloor]()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MeterReaderKeeper", category: "AddEditMeterVC")
    
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
    
    private let buildingLabel: UILabel = {
        let label = UILabel()
        label.text = "Building"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var buildingTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Select building"
        textField.borderStyle = .roundedRect
        textField.inputView = buildingPickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let floorLabel: UILabel = {
        let label = UILabel()
        label.text = "Floor"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var floorTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Select floor"
        textField.borderStyle = .roundedRect
        textField.inputView = floorPickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Meter Name"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter meter name"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .words
        textField.returnKeyType = .next
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Description"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var descriptionTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter description"
        textField.borderStyle = .roundedRect
        textField.returnKeyType = .done
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let imageLabel: UILabel = {
        let label = UILabel()
        label.text = "Meter Image (Optional)"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var meterImageImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var addImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Choose Image", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "photo"), for: .normal)
        button.addTarget(self, action: #selector(addImageTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
        button.setTitle("Delete Meter", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var buildingPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
    
    private lazy var floorPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        return picker
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
        
        contentView.addSubview(buildingLabel)
        contentView.addSubview(buildingTextField)
        contentView.addSubview(floorLabel)
        contentView.addSubview(floorTextField)
        contentView.addSubview(nameLabel)
        contentView.addSubview(nameTextField)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(descriptionTextField)
        contentView.addSubview(imageLabel)
        contentView.addSubview(meterImageImageView)
        contentView.addSubview(addImageButton)
        contentView.addSubview(saveButton)
        
        if meter != nil {
            contentView.addSubview(deleteButton)
        }
    }
    
    private func setupConstraints() {
        let deleteButtonConstraints: [NSLayoutConstraint]
        
        if meter != nil {
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
            
            // Building Label
            buildingLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            buildingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            buildingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Building TextField
            buildingTextField.topAnchor.constraint(equalTo: buildingLabel.bottomAnchor, constant: 8),
            buildingTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            buildingTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            buildingTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Floor Label
            floorLabel.topAnchor.constraint(equalTo: buildingTextField.bottomAnchor, constant: 20),
            floorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            floorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Floor TextField
            floorTextField.topAnchor.constraint(equalTo: floorLabel.bottomAnchor, constant: 8),
            floorTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            floorTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            floorTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: floorTextField.bottomAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Name TextField
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Description Label
            descriptionLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Description TextField
            descriptionTextField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            descriptionTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            descriptionTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Image Label
            imageLabel.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 20),
            imageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Image ImageView
            meterImageImageView.topAnchor.constraint(equalTo: imageLabel.bottomAnchor, constant: 8),
            meterImageImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            meterImageImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            meterImageImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Add Image Button
            addImageButton.topAnchor.constraint(equalTo: meterImageImageView.bottomAnchor, constant: 12),
            addImageButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Save Button
            saveButton.topAnchor.constraint(equalTo: addImageButton.bottomAnchor, constant: 32),
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
        buildings = (try? repository.getBuildings()) ?? []
        
        // Auto-select if only one building
        if building == nil, buildings.count == 1 {
            building = buildings[0]
        }
        buildingTextField.text = building?.name
        floors = building?.sortedFloors ?? []
        
        if let floor = floor {
            floorTextField.text = "Floor \(floor.number)"
        }
        
        // If editing existing meter
        if let meter = meter {
            nameTextField.text = meter.name
            descriptionTextField.text = meter.meterDescription
            
            if meter.imageData != Data(), let image = UIImage(data: meter.imageData) {
                meterImageImageView.image = image
            } else {
                meterImageImageView.image = UIImage(systemName: "gauge")
                meterImageImageView.tintColor = .systemGray3
            }
            
            title = "Edit Meter"
        } else {
            meterImageImageView.image = UIImage(systemName: "gauge")
            meterImageImageView.tintColor = .systemGray3
            title = "Add Meter"
        }
    }
    
    // MARK: - Actions
    @objc private func saveTapped() {
        guard let validationResult = validateInput() else {
            return
        }
        
        let (selectedFloor, meterName, meterDescription) = validationResult
        
        var imageData = Data()
        if let image = meterImageImageView.image, meterImageImageView.tintColor == nil {
            imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
        }
        
        let input = MRKMeterInput(name: meterName, description: meterDescription, imageData: imageData, floorID: selectedFloor.id)
        
        do {
            if let existingMeter = meter {
                _ = try repository.updateMeter(id: existingMeter.id, input: input)
                logger.info("Updated meter: \(meterName)")
            } else {
                _ = try repository.addMeter(input)
                logger.info("Created meter: \(meterName)")
            }
            navigationController?.popViewController(animated: true)
        } catch {
            logger.error("Failed to save meter: \(error.localizedDescription)")
            showAlert(title: "Save Failed", message: error.localizedDescription)
        }
    }
    
    @objc private func deleteTapped() {
        guard let meter = meter else {
            logger.warning("Delete tapped but no meter to delete")
            return
        }
        
        let alert = UIAlertController(
            title: "Delete Meter",
            message: "Are you sure you want to delete '\(meter.name)'? This will also delete all readings for this meter.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            do {
                try self.repository.deleteMeter(id: meter.id)
                self.logger.info("Deleted meter: \(meter.name)")
                self.navigationController?.popViewController(animated: true)
            } catch {
                self.showAlert(title: "Delete Failed", message: error.localizedDescription)
            }
        })
        
        present(alert, animated: true)
    }
    
    @objc private func addImageTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showAlert(title: "Not Available", message: "Photo library is not available")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Validation
    private func validateInput() -> (floor: MRKFloor, name: String, description: String)? {
        guard building != nil else {
            showAlert(title: "Missing Building", message: "Please select a building")
            return nil
        }
        
        guard let floor = floor else {
            showAlert(title: "Missing Floor", message: "Please select a floor")
            return nil
        }
        
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            showAlert(title: "Missing Name", message: "Please enter a meter name")
            return nil
        }
        
        let description = descriptionTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        return (floor, name, description)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerViewDelegate & DataSource
extension AddEditMeterViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == buildingPickerView {
            return buildings.count
        } else if pickerView == floorPickerView {
            return floors.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == buildingPickerView {
            return buildings[row].name
        } else if pickerView == floorPickerView {
            return "Floor \(floors[row].number)"
        }
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == buildingPickerView {
            building = buildings[row]
            buildingTextField.text = building?.name
            
            // Update floors for selected building
            floors = building?.sortedFloors ?? []
            floor = nil
            floorTextField.text = ""
            floorPickerView.reloadAllComponents()
            
            logger.info("Building selected: \(self.building?.name ?? "nil")")
        } else if pickerView == floorPickerView {
            floor = floors[row]
            floorTextField.text = "Floor \(floor?.number ?? 0)"
            logger.info("Floor selected: \(self.floor?.number ?? 0)")
        }
    }
}

// MARK: - UITextFieldDelegate
extension AddEditMeterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            descriptionTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AddEditMeterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            meterImageImageView.image = pickedImage
            meterImageImageView.tintColor = nil
            logger.info("Meter image selected")
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
