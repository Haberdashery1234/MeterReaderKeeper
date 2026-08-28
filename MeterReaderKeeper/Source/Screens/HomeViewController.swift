//
//  HomeViewController.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 5/2/21.
//  Refactored to programmatic UI on 8/25/26.
//  Updated to use MeterRepositoryProtocol on 8/26/26.
//  Thinned to use HomeViewModel on 8/26/26.
//  Redesigned to match the "Soft Cards" mockup (muted single-accent,
//  At a Glance stats, Needs Attention list) on 8/28/26.
//

import UIKit

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var viewModel: HomeViewModel!
    
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

    /// Top-level vertical layout. Sections are added as arranged subviews;
    /// the gaps between specific sections are set with `setCustomSpacing`
    /// below rather than a single uniform `spacing`, to match the rhythm
    /// from the redesign mockup.
    private let rootStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Meter Reader Keeper"
        label.font = .systemFont(ofSize: 34, weight: .heavy)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Manage building meters and readings"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var takeReadingsButton = createActionCard(
        title: "Take Readings",
        systemImage: "gauge.medium",
        action: #selector(takeReadingsTapped)
    )
    
    private lazy var previousReadingsButton = createActionCard(
        title: "Previous Readings",
        systemImage: "clock.arrow.circlepath",
        action: #selector(previousReadingsTapped)
    )
    
    private lazy var manageButton = createActionCard(
        title: "Manage Buildings & Meters",
        systemImage: "building.2",
        action: #selector(manageTapped)
    )
    
    private lazy var exportButton = createActionCard(
        title: "Export Data",
        systemImage: "square.and.arrow.up",
        action: #selector(exportDataTapped)
    )
    
    private lazy var actionsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            takeReadingsButton, previousReadingsButton, manageButton, exportButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    // MARK: At a Glance

    private let buildingCountValueLabel = HomeViewController.makeStatValueLabel()
    private let meterCountValueLabel = HomeViewController.makeStatValueLabel()
    private let lastReadingValueLabel = HomeViewController.makeStatValueLabel(fontSize: 15)

    private lazy var atGlanceCard: UIView = {
        let buildingsColumn = makeStatColumn(valueLabel: buildingCountValueLabel, caption: "Buildings")
        let metersColumn = makeStatColumn(valueLabel: meterCountValueLabel, caption: "Meters")
        let lastReadingColumn = makeStatColumn(valueLabel: lastReadingValueLabel, caption: "Last Reading")

        let row = UIStackView(arrangedSubviews: [buildingsColumn, makeDivider(vertical: true), metersColumn, makeDivider(vertical: true), lastReadingColumn])
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 0
        row.translatesAutoresizingMaskIntoConstraints = false

        let card = makeCardContainer()
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor),
        ])
        return card
    }()

    private lazy var atGlanceSection: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [makeSectionHeaderLabel("At a Glance"), atGlanceCard])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        return stackView
    }()

    // MARK: Needs Attention

    private let needsAttentionRowsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var needsAttentionCard: UIView = {
        let card = makeCardContainer()
        card.addSubview(needsAttentionRowsStackView)
        needsAttentionRowsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            needsAttentionRowsStackView.topAnchor.constraint(equalTo: card.topAnchor),
            needsAttentionRowsStackView.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            needsAttentionRowsStackView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            needsAttentionRowsStackView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
        ])
        return card
    }()

    /// Hidden until `loadSummary()` reports at least one overdue meter —
    /// there's nothing useful to show (or hide behind an empty card)
    /// otherwise.
    private lazy var needsAttentionSection: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [makeSectionHeaderLabel("Needs Attention"), needsAttentionCard])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.isHidden = true
        return stackView
    }()
    
    #if DEBUG
    private lazy var seedDataButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Seed Test Data", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        button.setTitleColor(.tertiaryLabel, for: .normal)
        button.addTarget(self, action: #selector(seedDataTapped), for: .touchUpInside)
        return button
    }()

    private lazy var seedDataRow: UIView = {
        let container = UIView()
        container.addSubview(seedDataButton)
        seedDataButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            seedDataButton.topAnchor.constraint(equalTo: container.topAnchor),
            seedDataButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            seedDataButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        ])
        return container
    }()
    #endif

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSummary()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(rootStackView)

        rootStackView.addArrangedSubview(headerStackView)
        rootStackView.addArrangedSubview(actionsStackView)
        rootStackView.addArrangedSubview(atGlanceSection)
        rootStackView.addArrangedSubview(needsAttentionSection)

        #if DEBUG
        rootStackView.addArrangedSubview(seedDataRow)
        #endif

        rootStackView.setCustomSpacing(28, after: actionsStackView)
        rootStackView.setCustomSpacing(26, after: atGlanceSection)
        rootStackView.setCustomSpacing(22, after: needsAttentionSection)
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

            // Root stack
            rootStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            rootStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            rootStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            rootStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            // Action card heights
            takeReadingsButton.heightAnchor.constraint(equalToConstant: 56),
            previousReadingsButton.heightAnchor.constraint(equalToConstant: 56),
            manageButton.heightAnchor.constraint(equalToConstant: 56),
            exportButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    // MARK: - View factories

    /// Icon + title, styled as an individually-cardified row: white
    /// (adaptive) background, hairline border, subtle shadow, no chevron —
    /// matches the "Soft Cards" Home redesign.
    private func createActionCard(title: String, systemImage: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .secondarySystemGroupedBackground
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.05
        button.layer.shadowRadius = 3
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityLabel = title
        button.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: systemImage))
        icon.tintColor = UIColor(named: "AccentColor")
        icon.contentMode = .scaleAspectFit
        icon.isUserInteractionEnabled = false
        icon.isAccessibilityElement = false
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.isUserInteractionEnabled = false
        label.isAccessibilityElement = false
        label.translatesAutoresizingMaskIntoConstraints = false

        button.addSubview(icon)
        button.addSubview(label)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 18),
            icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            label.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -18),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])

        return button
    }

    private func makeCardContainer() -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.separator.cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.05
        card.layer.shadowRadius = 3
        card.layer.shadowOffset = CGSize(width: 0, height: 1)
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }

    private func makeSectionHeaderLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }

    private static func makeStatValueLabel(fontSize: CGFloat = 22) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: fontSize, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.text = "\u{2013}"
        return label
    }

    private func makeStatColumn(valueLabel: UILabel, caption: String) -> UIView {
        let captionLabel = UILabel()
        captionLabel.text = caption
        captionLabel.font = .systemFont(ofSize: 12, weight: .regular)
        captionLabel.textColor = .secondaryLabel
        captionLabel.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [valueLabel, captionLabel])
        stackView.axis = .vertical
        stackView.spacing = 3
        stackView.alignment = .fill
        return stackView
    }

    private func makeDivider(vertical: Bool) -> UIView {
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        if vertical {
            divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
        } else {
            divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        }
        return divider
    }

    /// One row in the "Needs Attention" card: the meter's location on the
    /// left, days-since-last-reading (or "Never") and a chevron on the
    /// right. Tapping jumps straight into adding a reading for that meter.
    private func makeOverdueRow(_ item: HomeViewModel.OverdueMeterSummary) -> UIView {
        let locationLabel = UILabel()
        locationLabel.text = item.label
        locationLabel.font = .systemFont(ofSize: 14, weight: .medium)
        locationLabel.textColor = .label
        locationLabel.lineBreakMode = .byTruncatingTail
        locationLabel.isAccessibilityElement = false

        let daysDescription = item.daysSinceReading.map { "\($0) days since last reading" } ?? "Never read"
        let daysLabel = UILabel()
        daysLabel.text = item.daysSinceReading.map { "\($0)d" } ?? "Never"
        daysLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        daysLabel.textColor = .systemOrange
        daysLabel.isAccessibilityElement = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.isAccessibilityElement = false
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let trailingStack = UIStackView(arrangedSubviews: [daysLabel, chevron])
        trailingStack.axis = .horizontal
        trailingStack.spacing = 6
        trailingStack.alignment = .center
        trailingStack.setContentHuggingPriority(.required, for: .horizontal)

        let rowStack = UIStackView(arrangedSubviews: [locationLabel, trailingStack])
        rowStack.axis = .horizontal
        rowStack.spacing = 10
        rowStack.alignment = .center
        rowStack.isLayoutMarginsRelativeArrangement = true
        rowStack.layoutMargins = UIEdgeInsets(top: 13, left: 16, bottom: 13, right: 16)
        rowStack.isUserInteractionEnabled = false
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        let row = UIControl()
        row.isAccessibilityElement = true
        row.accessibilityLabel = item.label
        row.accessibilityValue = daysDescription
        row.accessibilityTraits = .button
        row.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: row.topAnchor),
            rowStack.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            rowStack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
        ])
        row.addAction(UIAction { [weak self] _ in
            self?.coordinator?.showAddReading(for: item.meter, floor: item.floor, building: item.building)
        }, for: .touchUpInside)
        row.addAction(UIAction { [weak row] _ in row?.backgroundColor = .systemGray5 }, for: .touchDown)
        row.addAction(UIAction { [weak row] _ in row?.backgroundColor = .clear }, for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])

        return row
    }

    // MARK: - Data

    private func loadSummary() {
        Task { @MainActor in
            let summary = await viewModel.loadSummary()
            apply(summary)
        }
    }

    private func apply(_ summary: HomeViewModel.HomeSummary) {
        buildingCountValueLabel.text = "\(summary.buildingCount)"
        meterCountValueLabel.text = "\(summary.meterCount)"
        lastReadingValueLabel.text = summary.lastReadingText

        needsAttentionRowsStackView.arrangedSubviews.forEach {
            needsAttentionRowsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for (index, item) in summary.overdueMeters.enumerated() {
            if index > 0 {
                needsAttentionRowsStackView.addArrangedSubview(makeDivider(vertical: false))
            }
            needsAttentionRowsStackView.addArrangedSubview(makeOverdueRow(item))
        }

        needsAttentionSection.isHidden = summary.overdueMeters.isEmpty
    }
    
    // MARK: - Actions
    @objc private func takeReadingsTapped() {
        Task { @MainActor in
            switch await viewModel.takeReadingsOutcome() {
            case .noBuildings:
                showAlert(
                    title: "No Buildings",
                    message: "Please add buildings and meters before taking readings."
                )
            case .singleBuilding(let building):
                coordinator?.showReadings(for: building)
            case .chooseBuilding(let buildings):
                showBuildingPicker(buildings: buildings)
            }
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

        Task { @MainActor in
            do {
                let plistData = try await viewModel.exportData()
                loadingAlert.dismiss(animated: true) {
                    self.sendPlist(plistData)
                }
            } catch {
                loadingAlert.dismiss(animated: true) {
                    self.showAlert(title: "Export Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    #if DEBUG
    @objc private func seedDataTapped() {
        seedDataButton.isEnabled = false

        let loadingAlert = UIAlertController(title: nil, message: "Seeding data...", preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        loadingAlert.view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            spinner.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20)
        ])
        present(loadingAlert, animated: true)

        Task { @MainActor in
            do {
                let outcome = try await viewModel.seedData()
                seedDataButton.isEnabled = true
                loadingAlert.dismiss(animated: true) {
                    switch outcome {
                    case .seededInitialData:
                        self.showAlert(title: "Success", message: "Test data has been seeded successfully.")
                    case .addedMoreReadings:
                        self.showAlert(title: "Success", message: "Additional readings have been added successfully.")
                    }
                }
                self.loadSummary()
            } catch {
                seedDataButton.isEnabled = true
                loadingAlert.dismiss(animated: true) {
                    self.showAlert(title: "Seed Failed", message: error.localizedDescription)
                }
            }
        }
    }
    #endif
    
    // MARK: - Private Methods
    private func sendPlist(_ plistData: Data) {
        EmailService.shared.sendExport(from: self, plistData: plistData) { [weak self] result, error in
            if result == .failed {
                self?.showAlert(title: "Send Failed", message: "Failed to send email. Please try again.")
            }
        }
    }
    
    private func showBuildingPicker(buildings: [MRKBuilding]) {
        let alert = UIAlertController(title: "Select Building", message: nil, preferredStyle: .actionSheet)
        
        for building in buildings {
            alert.addAction(UIAlertAction(title: building.name, style: .default) { [weak self] _ in
                self?.coordinator?.showReadings(for: building)
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
}
