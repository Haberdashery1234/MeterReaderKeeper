//
//  AddEditFloorViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//  Refactored to programmatic UI on 8/25/26.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//

import UIKit
import os.log

class AddEditFloorViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var repository: MeterRepositoryProtocol!
    var building: MRKBuilding?
    var floor: MRKFloor?
    
    private var buildings = [MRKBuilding]()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MeterReaderKeeper", category: "AddEditFloorVC")
    
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
        label.text = "Floor Number"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var floorTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter floor number"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let mapLabel: UILabel = {
        let label = UILabel()
        label.text = "Floor Map (Optional)"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var currentMapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var addMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Choose Map Image", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "photo"), for: .normal)
        button.addTarget(self, action: #selector(addMapTapped), for: .touchUpInside)
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
    
    private lazy var buildingPickerView: UIPickerView = {
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
        contentView.addSubview(mapLabel)
        contentView.addSubview(currentMapImageView)
        contentView.addSubview(addMapButton)
        contentView.addSubview(saveButton)
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
            floorLabel.topAnchor.constraint(equalTo: buildingTextField.bottomAnchor, constant: 24),
            floorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            floorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Floor TextField
            floorTextField.topAnchor.constraint(equalTo: floorLabel.bottomAnchor, constant: 8),
            floorTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            floorTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            floorTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Map Label
            mapLabel.topAnchor.constraint(equalTo: floorTextField.bottomAnchor, constant: 24),
            mapLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mapLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Map ImageView
            currentMapImageView.topAnchor.constraint(equalTo: mapLabel.bottomAnchor, constant: 8),
            currentMapImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            currentMapImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            currentMapImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Add Map Button
            addMapButton.topAnchor.constraint(equalTo: currentMapImageView.bottomAnchor, constant: 12),
            addMapButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Save Button
            saveButton.topAnchor.constraint(equalTo: addMapButton.bottomAnchor, constant: 32),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
        ])
    }
    
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func populateData() {
        buildings = (try? repository.getBuildings()) ?? []
        
        if building == nil, buildings.count == 1 {
            building = buildings[0]
        }
        buildingTextField.text = building?.name
        
        if let floor = floor {
            // building was supplied by the coordinator for the edit flow.
            floorTextField.text = "\(floor.number)"
            
            if floor.mapImageData != Data(), let mapImage = UIImage(data: floor.mapImageData) {
                currentMapImageView.image = mapImage
            } else {
                currentMapImageView.image = UIImage(systemName: "map")
                currentMapImageView.tintColor = .systemGray3
            }
            
            title = "Edit Floor"
        } else {
            currentMapImageView.image = UIImage(systemName: "map")
            currentMapImageView.tintColor = .systemGray3
            title = "Add Floor"
        }
    }
    
    // MARK: - Actions
    @objc private func addMapTapped() {
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
    
    @objc private func saveTapped() {
        guard let validationResult = validateInput() else {
            return
        }
        
        let (selectedBuilding, floorNumber) = validationResult
        
        var mapData = Data()
        if let image = currentMapImageView.image, currentMapImageView.tintColor == nil {
            mapData = image.jpegData(compressionQuality: 0.8) ?? Data()
        }
        
        let input = MRKFloorInput(number: floorNumber, mapImageData: mapData, buildingID: selectedBuilding.id)
        
        do {
            if let existingFloor = floor {
                _ = try repository.updateFloor(id: existingFloor.id, input: input)
            } else {
                _ = try repository.addFloor(input)
            }
            logger.info("Saved floor \(floorNumber) for building \(selectedBuilding.name)")
            navigationController?.popViewController(animated: true)
        } catch {
            logger.error("Failed to save floor: \(error.localizedDescription)")
            showAlert(title: "Save Failed", message: error.localizedDescription)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Validation
    private func validateInput() -> (building: MRKBuilding, floorNumber: Int16)? {
        guard let building = building else {
            showAlert(title: "Missing Building", message: "Please select a building")
            return nil
        }
        
        guard let floorText = floorTextField.text,
              let floorNumber = Int16(floorText) else {
            showAlert(title: "Invalid Floor", message: "Please enter a valid floor number")
            return nil
        }
        
        guard floorNumber > 0 else {
            showAlert(title: "Invalid Floor", message: "Floor number must be greater than 0")
            return nil
        }
        
        return (building, floorNumber)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerViewDelegate & DataSource
extension AddEditFloorViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return buildings.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return buildings[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        building = buildings[row]
        buildingTextField.text = building?.name
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AddEditFloorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            currentMapImageView.image = pickedImage
            currentMapImageView.tintColor = nil
            logger.info("Floor map image selected")
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
