//
//  AddEditMeterViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/2/21.
//  Refactored to programmatic UI on 8/25/26.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//  Thinned to use AddEditMeterViewModel on 8/26/26.
//

import UIKit

/// The Add/Edit Meter form: building and floor pickers, name/description
/// text fields, an optional photo, and (when editing) a Delete button.
/// Owns all UI presentation; `AddEditMeterViewModel` owns validation and
/// the save/delete calls into the repository.
class AddEditMeterViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var viewModel: AddEditMeterViewModel!
    
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
        AppStyle.stylePaddedTextField(textField)
        textField.inputView = buildingPickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "AddEditMeter.buildingTextField"
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
        AppStyle.stylePaddedTextField(textField)
        textField.inputView = floorPickerView
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "AddEditMeter.floorTextField"
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
        AppStyle.stylePaddedTextField(textField)
        textField.autocapitalizationType = .words
        textField.returnKeyType = .next
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "AddEditMeter.nameTextField"
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
        AppStyle.stylePaddedTextField(textField)
        textField.returnKeyType = .done
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "AddEditMeter.descriptionTextField"
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
        AppStyle.styleImageWell(imageView)
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
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete Meter", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "AddEditMeter.deleteButton"
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
        setupNavigationBar()
        populateData()
    }
    
    // MARK: - Setup

    /// Adds every field to the view hierarchy, including the Delete button
    /// only when editing an existing meter.
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
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
        
        if viewModel.isEditing {
            contentView.addSubview(deleteButton)
        }
    }

    /// Adds the Save action as the standard Apple paradigm: a right nav bar button, always visible above the keyboard.
    private func setupNavigationBar() {
        let saveItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        saveItem.accessibilityIdentifier = "AddEditMeter.saveButton"
        navigationItem.rightBarButtonItem = saveItem
    }
    
    /// Activates the form's Auto Layout constraints top-to-bottom, anchoring
    /// the bottom of the content either to the Delete button (editing) or
    /// the Save button (adding).
    private func setupConstraints() {
        let deleteButtonConstraints: [NSLayoutConstraint]
        
        if viewModel.isEditing {
            deleteButtonConstraints = [
                deleteButton.topAnchor.constraint(equalTo: addImageButton.bottomAnchor, constant: 32),
                deleteButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                deleteButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            ]
        } else {
            deleteButtonConstraints = [
                addImageButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
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
            
        ] + deleteButtonConstraints)
    }
    
    /// Dismisses the keyboard on a tap anywhere outside the active text field.
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    /// Loads the building/floor picker data, then fills every field from
    /// `viewModel`'s current state (existing values when editing, a
    /// placeholder icon when there's no image yet).
    private func populateData() {
        Task { @MainActor in
            await viewModel.loadBuildingsAndFloors()
            buildingTextField.text = viewModel.selectedBuilding?.name
            floorTextField.text = viewModel.initialFloorText

            // Sync each picker's highlighted row to whatever got
            // auto-selected/pre-populated above (a single building,
            // or — when editing — the meter's existing building/floor)
            // so opening the picker shows the right row highlighted
            // instead of the "Select Building"/"Select Floor"
            // placeholder at row 0. Added 2026-09-02 alongside that
            // placeholder row — see `didSelectRow`'s doc comment.
            buildingPickerView.reloadAllComponents()
            floorPickerView.reloadAllComponents()
            if let building = viewModel.selectedBuilding,
               let buildingRow = viewModel.buildings.firstIndex(where: { $0.id == building.id }) {
                buildingPickerView.selectRow(buildingRow + 1, inComponent: 0, animated: false)
            }
            if let floor = viewModel.selectedFloor,
               let floorRow = viewModel.floors.firstIndex(where: { $0.id == floor.id }) {
                floorPickerView.selectRow(floorRow + 1, inComponent: 0, animated: false)
            }

            if viewModel.isEditing {
                nameTextField.text = viewModel.initialNameText
                descriptionTextField.text = viewModel.initialDescriptionText
            }

            if let imageData = viewModel.initialImageData, let image = UIImage(data: imageData) {
                meterImageImageView.image = image
            } else {
                meterImageImageView.image = UIImage(systemName: "gauge")
                meterImageImageView.tintColor = .systemGray3
            }

            title = viewModel.screenTitle
        }
    }
    
    // MARK: - Actions

    /// Validates and saves the form, popping back on success or showing an
    /// alert on failure. `imageData` stays empty `Data()` unless the image
    /// view is showing a real picked photo (its `tintColor == nil` is how
    /// this tells that apart from the gray placeholder icon).
    @objc private func saveTapped() {
        var imageData = Data()
        if let image = meterImageImageView.image, meterImageImageView.tintColor == nil {
            imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
        }
        
        Task { @MainActor in
            do {
                _ = try await viewModel.save(nameText: nameTextField.text, descriptionText: descriptionTextField.text, imageData: imageData)
                navigationController?.popViewController(animated: true)
            } catch let error as FormValidationError {
                showAlert(title: error.title, message: error.message)
            } catch {
                print("Failed to save meter: \(error.localizedDescription)")
                showAlert(title: "Save Failed", message: error.localizedDescription)
            }
        }
    }
    
    /// Presents a confirmation alert before deleting the meter (and its
    /// reading history), popping back on success.
    @objc private func deleteTapped() {
        guard let meter = viewModel.meter else {
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
    
    /// Presents the system photo picker to choose a meter photo.
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

    /// Presents a simple single-button ("OK") alert.
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIPickerViewDelegate & DataSource
// One shared delegate/data source pair handles both `buildingPickerView`
// and `floorPickerView`, branching on which picker is asking.
extension AddEditMeterViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // Row 0 in both pickers is a "Select Building"/"Select Floor"
    // placeholder, not a real value — see the doc comment on
    // `didSelectRow` below for why. Every real row is offset by 1.
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == buildingPickerView {
            return viewModel.buildings.count + 1
        } else if pickerView == floorPickerView {
            return viewModel.floors.count + 1
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == buildingPickerView {
            guard row > 0 else { return "Select Building" }
            return viewModel.buildings[row - 1].name
        } else if pickerView == floorPickerView {
            guard row > 0 else { return "Select Floor" }
            return "Floor \(viewModel.floors[row - 1].number)"
        }
        return ""
    }
    
    /// Row 0 of each picker is a non-selectable "Select Building"/
    /// "Select Floor" placeholder — added 2026-09-02. Without it,
    /// `UIPickerView` opens already showing its first real row (e.g.
    /// "Floor 1") highlighted, but never actually calls this delegate
    /// method for that row unless the user scrolls away from it and
    /// back — so someone (or a UI test driving
    /// `adjust(toPickerWheelValue:)`, which also does nothing if the
    /// wheel is already showing the requested value) who wants exactly
    /// that first row and doesn't scroll ends up with
    /// `viewModel.selectedBuilding`/`.selectedFloor` still `nil` even
    /// though the field visually shows a value, and Save then fails
    /// validation with a "Missing Building"/"Missing Floor" alert
    /// nobody asked for. The placeholder forces every real selection to
    /// be an actual scroll, so this method always fires. Root-caused by
    /// Christian; see "UI test flakiness, root cause: picker default
    /// row never fires didSelectRow (2026-09-02)" in project memory.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == buildingPickerView {
            guard row > 0 else {
                viewModel.clearBuildingSelection()
                buildingTextField.text = nil
                floorTextField.text = nil
                floorPickerView.reloadAllComponents()
                floorPickerView.selectRow(0, inComponent: 0, animated: false)
                return
            }
            let building = viewModel.selectBuilding(at: row - 1)
            buildingTextField.text = building?.name
            floorTextField.text = ""
            floorPickerView.reloadAllComponents()
            floorPickerView.selectRow(0, inComponent: 0, animated: false)
        } else if pickerView == floorPickerView {
            guard row > 0 else {
                viewModel.clearFloorSelection()
                floorTextField.text = nil
                return
            }
            let floor = viewModel.selectFloor(at: row - 1)
            floorTextField.text = floor.map { "Floor \($0.number)" } ?? ""
        }
    }
}

// MARK: - UITextFieldDelegate
extension AddEditMeterViewController: UITextFieldDelegate {
    /// Advances from Name to Description, or dismisses the keyboard from
    /// any other field, on the return key.
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
    /// Displays the picked (or edited) photo and clears the placeholder tint.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            meterImageImageView.image = pickedImage
            meterImageImageView.tintColor = nil
            print("Meter image selected")
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
