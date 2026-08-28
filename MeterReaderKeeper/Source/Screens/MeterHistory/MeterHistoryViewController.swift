//
//  MeterHistoryViewController.swift
//  MeterReaderKeeper
//
//  Created for the meter details screen on 2026-08-28. Reached by tapping a
//  meter row on Previous Readings (Christian: "Selecting a meter from the
//  previous readings screen should take me to a meter details screen,
//  showing details about the meter: Building, floor, most recent reading
//  value, and a chart showing the meter readings over time."). Styled to
//  match the rest of the app-wide redesign (AppStyle soft cards on a
//  grouped background).
//
//  The reading-history chart originally used Apple's SwiftUI-only Swift
//  Charts framework via a UIHostingController. Christian asked to keep this
//  screen pure UIKit instead (2026-08-28), so it was switched to DGCharts
//  (SPM: ChartsOrg/Charts — the library's product was renamed from `Charts`
//  to `DGCharts` starting at 5.0.0 specifically to avoid colliding with
//  Apple's own Charts framework). See `MeterReaderKeeper.xcodeproj` for the
//  added package reference; Xcode resolves it from the network on first
//  build.
//

import UIKit
import DGCharts

class MeterHistoryViewController: UIViewController {

    // MARK: - Properties
    weak var coordinator: AppCoordinator?
    var viewModel: MeterHistoryViewModel!

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

    private let rootStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: Details card (Building / Floor / Latest Reading)

    private let buildingValueLabel = MeterHistoryViewController.makeStatValueLabel(fontSize: 16)
    private let floorValueLabel = MeterHistoryViewController.makeStatValueLabel(fontSize: 16)

    private lazy var buildingFloorRow: UIView = {
        let buildingColumn = makeStatColumn(valueLabel: buildingValueLabel, caption: "Building")
        let floorColumn = makeStatColumn(valueLabel: floorValueLabel, caption: "Floor")

        let row = UIStackView(arrangedSubviews: [buildingColumn, AppStyle.makeDivider(vertical: true), floorColumn])
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fillEqually
        row.spacing = 0
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }()

    private let latestReadingValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.text = "\u{2013}"
        return label
    }()

    private let latestReadingCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Latest Reading"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let latestReadingDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

    private lazy var latestReadingStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [latestReadingValueLabel, latestReadingCaptionLabel, latestReadingDateLabel])
        stackView.axis = .vertical
        stackView.spacing = 3
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var detailsColumn: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [buildingFloorRow, AppStyle.makeDivider(vertical: false), latestReadingStack])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var detailsCard: UIView = {
        let card = AppStyle.makeCardContainer()
        card.addSubview(detailsColumn)
        NSLayoutConstraint.activate([
            detailsColumn.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            detailsColumn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            detailsColumn.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            detailsColumn.trailingAnchor.constraint(equalTo: card.trailingAnchor),
        ])
        return card
    }()

    // MARK: Reading history card (chart)

    private let chartContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let noReadingsLabel: UILabel = {
        let label = UILabel()
        label.text = "No readings recorded yet."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var historyCard: UIView = {
        let card = AppStyle.makeCardContainer()
        card.addSubview(chartContainerView)
        card.addSubview(noReadingsLabel)
        NSLayoutConstraint.activate([
            chartContainerView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            chartContainerView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            chartContainerView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            chartContainerView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            chartContainerView.heightAnchor.constraint(equalToConstant: 220),

            noReadingsLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            noReadingsLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            noReadingsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 24),
            noReadingsLabel.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -24),
        ])
        return card
    }()

    private lazy var historySection: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [AppStyle.makeSectionHeaderLabel("Reading History"), historyCard])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        return stackView
    }()

    /// Renders `MeterHistoryViewModel.chartPoints` with DGCharts. Configured
    /// once in `setupChart()`; `refreshUI()` only swaps `.data` as readings
    /// change. Interaction (pan/zoom/tap) is disabled because this view sits
    /// inside the screen's own `UIScrollView`, and DGCharts' own pan/pinch
    /// gestures would otherwise fight the outer scroll view's.
    private let lineChartView: LineChartView = {
        let chartView = LineChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.backgroundColor = .clear
        chartView.noDataText = ""

        chartView.legend.enabled = false
        chartView.rightAxis.enabled = false

        chartView.leftAxis.enabled = true
        chartView.leftAxis.drawGridLinesEnabled = true
        chartView.leftAxis.gridColor = UIColor.separator.withAlphaComponent(0.3)
        chartView.leftAxis.labelFont = .systemFont(ofSize: 11)
        chartView.leftAxis.labelTextColor = .secondaryLabel
        chartView.leftAxis.drawAxisLineEnabled = false

        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = true
        chartView.xAxis.gridColor = UIColor.separator.withAlphaComponent(0.3)
        chartView.xAxis.drawAxisLineEnabled = false
        chartView.xAxis.labelFont = .systemFont(ofSize: 11)
        chartView.xAxis.labelTextColor = .secondaryLabel
        chartView.xAxis.setLabelCount(4, force: false)
        chartView.xAxis.valueFormatter = MeterHistoryDateAxisFormatter()

        chartView.dragEnabled = false
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.highlightPerTapEnabled = false
        chartView.highlightPerDragEnabled = false

        return chartView
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupChart()
        refreshUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { @MainActor in
            await viewModel.refresh()
            refreshUI()
        }
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(rootStackView)

        rootStackView.addArrangedSubview(detailsCard)
        rootStackView.addArrangedSubview(historySection)
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
            rootStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            rootStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            rootStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            rootStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
    }

    private func setupChart() {
        chartContainerView.addSubview(lineChartView)
        NSLayoutConstraint.activate([
            lineChartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            lineChartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor),
            lineChartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            lineChartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
        ])
    }

    /// Single source of truth for reflecting `viewModel`'s current state —
    /// called once with the data passed in at construction (`viewDidLoad`)
    /// and again after every repository refresh (`viewWillAppear`).
    private func refreshUI() {
        buildingValueLabel.text = viewModel.buildingName
        floorValueLabel.text = viewModel.floorDisplayName
        latestReadingValueLabel.text = viewModel.formattedMostRecentValue
        latestReadingDateLabel.text = viewModel.formattedMostRecentDate

        let entries = viewModel.chartPoints.map { reading in
            ChartDataEntry(x: reading.date.timeIntervalSince1970, y: reading.kWh)
        }
        let dataSet = LineChartDataSet(entries: entries, label: "")
        dataSet.colors = [AppStyle.accent]
        dataSet.circleColors = [AppStyle.accent]
        dataSet.circleRadius = 3
        dataSet.circleHoleRadius = 1.5
        dataSet.lineWidth = 2
        dataSet.mode = .cubicBezier
        dataSet.drawValuesEnabled = false
        dataSet.drawCirclesEnabled = true

        lineChartView.data = LineChartData(dataSet: dataSet)

        let hasReadings = viewModel.hasReadings
        chartContainerView.isHidden = !hasReadings
        noReadingsLabel.isHidden = hasReadings
    }

    // MARK: - View factories

    private static func makeStatValueLabel(fontSize: CGFloat) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: fontSize, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
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
}

/// Converts a DGCharts x-value (stored as `Date.timeIntervalSince1970`, see
/// `refreshUI()`) back into a short "MMM d" axis label.
private final class MeterHistoryDateAxisFormatter: AxisValueFormatter {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}
