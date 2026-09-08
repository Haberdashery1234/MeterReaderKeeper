//
//  AddEditFloorViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/4/21.
//  Refactored to programmatic UI on 8/25/26.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//  Thinned to use AddEditFloorViewModel on 8/26/26.
//

import UIKit

/// Add/edit form for a single `MRKFloor`. Reused for both creating a new
/// floor and editing an existing one — `viewModel.isEditing` decides the
/// screen title and whether the floor-number field is pre-filled. Also
/// lets the user pick which building the floor belongs to (via
/// `buildingPickerView`) and attach an optional floor map image. Pushed by
/// `AppCoordinator.showFloorDetails(building:floor:)`.
class AddEditFloorViewController: UIViewController {

    // MARK: - Properties
    /// Used to pop back to the previous screen after a successful save.
    weak var coordinator: AppCoordinator?
    /// Supplies the form's initial values, the building list, and validates/persists a save.
    var viewModel: AddEditFloorViewModel!
    
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
        textField.accessibilityIdentifier = "AddEditFloor.buildingTextField"
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
        AppStyle.stylePaddedTextField(textField)
        textField.keyboardType = .numberPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.accessibilityIdentifier = "AddEditFloor.floorTextField"
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
        AppStyle.styleImageWell(imageView)
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
        setupNavigationBar()
        populateData()
    }

    // MARK: - Setup
    /// Adds the form's subviews.
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(buildingLabel)
        contentView.addSubview(buildingTextField)
        contentView.addSubview(floorLabel)
        contentView.addSubview(floorTextField)
        contentView.addSubview(mapLabel)
        contentView.addSubview(currentMapImageView)
        contentView.addSubview(addMapButton)
    }

    /// Adds the Save action as the standard Apple paradigm: a right nav bar button, always visible above the keyboard.
    private func setupNavigationBar() {
        let saveItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        saveItem.accessibilityIdentifier = "AddEditFloor.saveButton"
        navigationItem.rightBarButtonItem = saveItem
    }
    
    /// Lays out the form.
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
            addMapButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
        ])
    }
    
    /// Adds a tap-to-dismiss gesture so tapping outside a text field closes the keyboard.
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    /// Loads the building list for the picker, then fills the form from
    /// `viewModel`'s initial values. `currentMapImageView` falls back to a
    /// placeholder "map" glyph (tinted gray) when there's no existing map
    /// image, which `saveTapped()` uses to distinguish "no image" from "an
    /// actual picked image" via `currentMapImageView.tintColor == nil`.
    private func populateData() {
        Task { @MainActor in
            await viewModel.loadBuildings()
            buildingTextField.text = viewModel.selectedBuilding?.name

            // Sync the picker's highlighted row to whatever got
            // auto-selected/pre-populated above (a single building, or
            // — when editing — the floor's existing building) so
            // opening the picker shows the right row highlighted
            // instead of the "Select Building" placeholder at row 0.
            // Mirrors AddEditMeterViewController's populateData();
            // added 2026-09-08 — see `didSelectRow`'s doc comment below.
            buildingPickerView.reloadAllComponents()
            if let building = viewModel.selectedBuilding,
               let buildingRow = viewModel.buildings.firstIndex(where: { $0.id == building.id }) {
                buildingPickerView.selectRow(buildingRow + 1, inComponent: 0, animated: false)
            }

            if viewModel.isEditing {
                floorTextField.text = viewModel.initialFloorNumberText
            }

            if let mapData = viewModel.initialMapImageData, let mapImage = UIImage(data: mapData) {
                currentMapImageView.image = mapImage
            } else {
                currentMapImageView.image = UIImage(systemName: "map")
                currentMapImageView.tintColor = .systemGray3
            }

            title = viewModel.screenTitle
        }
    }

    // MARK: - Actions
    /// Presents a photo library picker for choosing a floor map image.
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
    
    /// Save button handler. Only treats `currentMapImageView.image` as new
    /// map data to persist when it's an actual picked photo (`tintColor ==
    /// nil` distinguishes that from the placeholder glyph set in
    /// `populateData()`); otherwise saves an empty `Data()`.
    @objc private func saveTapped() {
        var mapData = Data()
        if let image = currentMapImageView.image, currentMapImageView.tintColor == nil {
            mapData = image.jpegData(compressionQuality: 0.8) ?? Data()
        }
        
        Task { @MainActor in
            do {
                _ = try await viewModel.save(floorNumberText: floorTextField.text, mapImageData: mapData)
                navigationController?.popViewController(animated: true)
            } catch let error as FormValidationError {
                showAlert(title: error.title, message: error.message)
            } catch {
                print("Failed to save floor: \(error.localizedDescription)")
                showAlert(title: "Save Failed", message: error.localizedDescription)
            }
        }
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

// MARK: - UIPickerViewDelegate & DataSource
extension AddEditFloorViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // Row 0 is a "Select Building" placeholder, not a real value — see
    // the doc comment on `didSelectRow` below for why. Every real row
    // is offset by 1.
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.buildings.count + 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard row > 0 else { return "Select Building" }
        return viewModel.buildings[row - 1].name
    }

    /// Row 0 is a non-selectable "Select Building" placeholder — added
    /// 2026-09-08, mirroring the same fix already applied to
    /// `AddEditMeterViewController`. Without it, `UIPickerView` opens
    /// already showing its first real row highlighted, but never
    /// actually calls this delegate method for that row unless the
    /// user scrolls away from it and back — so someone who wants
    /// exactly that first building and doesn't scroll ends up with
    /// `viewModel.selectedBuilding` still `nil` even though the field
    /// visually shows a value, and Save then fails validation with a
    /// "Missing Building" alert nobody asked for. The placeholder
    /// forces every real selection to be an actual scroll, so this
    /// method always fires. Root-caused by Christian for
    /// `AddEditMeterViewController`; see "UI test flakiness, root
    /// cause: picker default row never fires didSelectRow
    /// (2026-09-02)" in project memory.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard row > 0 else {
            viewModel.clearBuildingSelection()
            buildingTextField.text = nil
            return
        }
        let building = viewModel.selectBuilding(at: row - 1)
        buildingTextField.text = building?.name
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AddEditFloorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /// Applies the picked (or edited) photo as the new map image, clearing
    /// `tintColor` so `saveTapped()` recognizes it as real image data rather
    /// than the placeholder glyph.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            currentMapImageView.image = pickedImage
            currentMapImageView.tintColor = nil
            print("Floor map image selected")
        }

        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
