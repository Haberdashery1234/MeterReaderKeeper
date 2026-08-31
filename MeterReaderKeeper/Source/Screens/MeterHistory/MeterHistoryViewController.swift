//
//  MeterHistoryViewController.swift
//  MeterReaderKeeper
//
//  Created for the meter details screen on 2026-08-28. Reached by tapping a
//  meter row on Previous Readings; shows the meter's building, floor, most
//  recent reading value, and a chart of its readings over time. Styled to
//  match the rest of the app-wide redesign (AppStyle soft cards on a
//  grouped background).
//
//  The reading-history chart originally used Apple's SwiftUI-only Swift
//  Charts framework via a UIHostingController, then was switched to
//  DGCharts (SPM: ChartsOrg/Charts — the library's product was renamed
//  from `Charts` to `DGCharts` starting at 5.0.0 specifically to avoid
//  colliding with Apple's own Charts framework) to keep this screen pure
//  UIKit (2026-08-28). See `MeterReaderKeeper.xcodeproj` for the added
//  package reference; Xcode resolves it from the network on first build.
//
//  The chart itself changed again the same day: it originally plotted raw
//  kWh readings as a line. Cumulative electric meters can roll over (wrap
//  back to 0 after exceeding their dial's digit capacity), so a raw-value
//  line can show a misleading downward spike on a legitimate rollover. The
//  chart was changed to show usage since the last reading instead of the
//  raw value, so this is now a `BarChartView` plotting
//  `MeterHistoryViewModel.usagePoints` (rollover-corrected kWh used
//  between consecutive readings — see `MRKReading.usage(from:to:)`), not
//  the raw readings.
//

import UIKit
import DGCharts

/// The read-only Meter Details screen: building/floor/most-recent-reading
/// summary plus a bar chart of usage over time. Reached by tapping a meter
/// row on Previous Readings. Owns all UI presentation and the DGCharts
/// setup; `MeterHistoryViewModel` owns the data behind it.
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

    /// Renders `MeterHistoryViewModel.usagePoints` with DGCharts as a bar
    /// per reading interval. Configured once in `setupChart()`;
    /// `refreshUI()` only swaps `.data` as readings change. Interaction
    /// (pan/zoom/tap) is disabled because this view sits inside the
    /// screen's own `UIScrollView`, and DGCharts' own pan/pinch gestures
    /// would otherwise fight the outer scroll view's.
    private let barChartView: BarChartView = {
        let chartView = BarChartView()
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
        chartView.leftAxis.axisMinimum = 0

        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.drawAxisLineEnabled = false
        chartView.xAxis.labelFont = .systemFont(ofSize: 11)
        chartView.xAxis.labelTextColor = .secondaryLabel
        chartView.xAxis.setLabelCount(4, force: false)
        chartView.xAxis.granularity = 1
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

    /// Re-fetches the meter (so a reading added elsewhere is reflected)
    /// every time this screen becomes visible.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { @MainActor in
            await viewModel.refresh()
            refreshUI()
        }
    }

    // MARK: - Setup

    /// Builds the view hierarchy and adds the details/history sections to
    /// `rootStackView`.
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(rootStackView)

        rootStackView.addArrangedSubview(detailsCard)
        rootStackView.addArrangedSubview(historySection)
    }

    /// Activates the scroll view / content view / root stack Auto Layout constraints.
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

    /// Pins `barChartView` inside `chartContainerView`. Configuring the
    /// chart's data is `refreshUI()`'s job, not this one-time layout step.
    private func setupChart() {
        chartContainerView.addSubview(barChartView)
        NSLayoutConstraint.activate([
            barChartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            barChartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor),
            barChartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            barChartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
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

        let usagePoints = viewModel.usagePoints
        let entries = usagePoints.map { point in
            BarChartDataEntry(x: point.date.timeIntervalSince1970, y: point.kWh)
        }
        let dataSet = BarChartDataSet(entries: entries, label: "")
        dataSet.colors = [AppStyle.accent]
        dataSet.drawValuesEnabled = false

        let barWidth = Self.barWidth(for: entries)
        let data = BarChartData(dataSet: dataSet)
        data.barWidth = barWidth
        barChartView.data = data

        // `BarChartData(dataSet:)` computes its cached `xMin`/`xMax` (which
        // DGCharts uses to auto-fit the x-axis) at *construction* time,
        // using whatever `barWidth` was in effect then — the library's own
        // default of 0.9, since we don't set our own `barWidth` until the
        // line above. That cache isn't recalculated just because `barWidth`
        // changes afterward, so the auto-fit axis range ends up sized for
        // a 0.9-wide bar instead of our real (much wider) one, and the
        // outer edges of the first/last bars — which extend `barWidth / 2`
        // past their x-value — get clipped at the plot boundary. Set the
        // axis range explicitly, padded for the actual bar width plus a
        // little breathing room, instead of relying on that auto-fit.
        // When there's nothing to plot, `chartContainerView` is hidden
        // below anyway (see `hasUsageData`), so the axis range is left
        // alone rather than reset through a DGCharts API this session
        // can't confirm the exact name of without a compiler on hand.
        let xValues = entries.map(\.x)
        if let xMin = xValues.min(), let xMax = xValues.max() {
            let padding = (barWidth / 2) + (barWidth * 0.1)
            barChartView.xAxis.axisMinimum = xMin - padding
            barChartView.xAxis.axisMaximum = xMax + padding
        }

        let hasUsageData = viewModel.hasUsageData
        chartContainerView.isHidden = !hasUsageData
        noReadingsLabel.text = viewModel.chartEmptyStateMessage
        noReadingsLabel.isHidden = hasUsageData
    }

    /// DGCharts bar widths are in the same units as the x-axis — here,
    /// seconds (`Date.timeIntervalSince1970`) — so the library's own
    /// default (0.9) would render as an imperceptible sliver against gaps
    /// of days between readings. Sizes each bar to 60% of the smallest gap
    /// between consecutive points instead, falling back to a chart with a
    /// single bar (no gap to measure) to a fixed width sized for readings a
    /// day apart.
    private static func barWidth(for entries: [BarChartDataEntry]) -> Double {
        let secondsPerDay = 60.0 * 60.0 * 24.0
        let xValues = entries.map(\.x).sorted()
        guard xValues.count > 1 else { return secondsPerDay * 0.6 }
        let gaps = zip(xValues, xValues.dropFirst()).map { $1 - $0 }
        let minGap = gaps.min() ?? secondsPerDay
        return minGap * 0.6
    }

    // MARK: - View factories

    /// A large, centered, auto-shrinking value label for the details card.
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

    /// A value label stacked over a caption — one column of the details card.
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

    /// - Parameters:
    ///   - value: A chart x-value, i.e. a `Date.timeIntervalSince1970`.
    ///   - axis: Unused — required by `AxisValueFormatter`.
    /// - Returns: The value formatted as a short "MMM d" date string.
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}
