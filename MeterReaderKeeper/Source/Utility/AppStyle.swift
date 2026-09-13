//
//  AppStyle.swift
//  MeterReaderKeeper
//
//  Created for the app-wide visual redesign on 2026-08-28. Shared styling
//  helpers for the "muted single-accent" look introduced on the Home
//  screen (soft cards on a grouped background, one accent color pulled
//  from Assets.xcassets/AccentColor) so every other screen can match it
//  without re-deriving the same constants.
//

import UIKit

/// Shared styling helpers for the app-wide "soft cards on a muted
/// single-accent" visual design. A caseless enum used purely as a
/// namespace — never instantiated.
enum AppStyle {

    /// Corner radius used by every card-style container and image well.
    static let cardCornerRadius: CGFloat = 14

    /// The single accent color for the whole app (see AccentColor.colorset).
    /// Prefer this over `.tintColor`/system defaults when a view needs the
    /// accent explicitly (e.g. an icon's `tintColor`), so there's exactly
    /// one place this color is ever spelled out.
    static var accent: UIColor {
        UIColor(named: "AccentColor") ?? .systemBlue
    }

    /// Returns a system font that scales with the user's preferred text
    /// size (Dynamic Type): wraps a fixed-size/weight system font in
    /// `UIFontMetrics` relative to `textStyle`, so it grows or shrinks the
    /// same way built-in Apple text of that style would. Pair with
    /// `applyScaledFont(to:...)` below when setting a label/button's font
    /// directly also needs `adjustsFontForContentSizeCategory` turned on.
    static func scaledFont(size: CGFloat, weight: UIFont.Weight = .regular, relativeTo textStyle: UIFont.TextStyle = .body) -> UIFont {
        let baseFont = UIFont.systemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: baseFont)
    }

    /// Sets `label`'s font to a Dynamic-Type-scaling font (see
    /// `scaledFont(size:weight:relativeTo:)`) and turns on
    /// `adjustsFontForContentSizeCategory`, so it keeps scaling if the
    /// setting changes while the label is on screen.
    static func applyScaledFont(to label: UILabel, size: CGFloat, weight: UIFont.Weight = .regular, relativeTo textStyle: UIFont.TextStyle = .body) {
        label.font = scaledFont(size: size, weight: weight, relativeTo: textStyle)
        label.adjustsFontForContentSizeCategory = true
    }

    /// Sets `button`'s title label font to a Dynamic-Type-scaling font and
    /// turns on `adjustsFontForContentSizeCategory`, mirroring
    /// `applyScaledFont(to: UILabel...)` above.
    static func applyScaledFont(to button: UIButton, size: CGFloat, weight: UIFont.Weight = .regular, relativeTo textStyle: UIFont.TextStyle = .body) {
        button.titleLabel?.font = scaledFont(size: size, weight: weight, relativeTo: textStyle)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    /// Applies the "soft card" look (used throughout the Home redesign) to
    /// an existing view: adaptive white background, hairline border,
    /// subtle shadow, rounded corners. Deliberately does not set
    /// `clipsToBounds`/`masksToBounds` — that would clip the shadow.
    static func applyCardStyle(to view: UIView) {
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = cardCornerRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 3
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
    }

    /// Creates an empty, auto-layout-ready view with the "soft card" style
    /// already applied.
    static func makeCardContainer() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        applyCardStyle(to: card)
        return card
    }

    /// Creates a hairline separator view, sized to one point (vertical) or
    /// one pixel (horizontal, via `1 / UIScreen.main.scale`).
    ///
    /// - Parameter vertical: `true` for a vertical divider (fixed width,
    ///   stretches to fill height), `false` for a horizontal one (fixed
    ///   height, stretches to fill width).
    static func makeDivider(vertical: Bool) -> UIView {
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

    /// Creates an uppercase, small-caps-styled section header label (e.g.
    /// "AT A GLANCE").
    static func makeSectionHeaderLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        applyScaledFont(to: label, size: 13, weight: .semibold, relativeTo: .footnote)
        label.textColor = .secondaryLabel
        return label
    }

    /// Styles a button as the accent-filled primary action on a form
    /// screen (e.g. "Save"). Replaces the old hardcoded `.systemBlue`.
    static func styleAsPrimaryButton(_ button: UIButton) {
        button.backgroundColor = accent
        button.setTitleColor(.white, for: .normal)
        applyScaledFont(to: button, size: 18, weight: .semibold, relativeTo: .headline)
        button.layer.cornerRadius = 12
    }

    /// Styles a `UITextField` as a card-style input row: adaptive card
    /// background instead of the default gray `.roundedRect` bezel, with
    /// left/right inset padding (UITextField has no built-in padding, so
    /// this is the standard `leftView`/`rightView` spacer trick).
    static func stylePaddedTextField(_ textField: UITextField, horizontalInset: CGFloat = 14) {
        textField.borderStyle = .none
        textField.backgroundColor = .secondarySystemGroupedBackground
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.separator.cgColor

        let leftSpacer = UIView(frame: CGRect(x: 0, y: 0, width: horizontalInset, height: 1))
        textField.leftView = leftSpacer
        textField.leftViewMode = .always

        let rightSpacer = UIView(frame: CGRect(x: 0, y: 0, width: horizontalInset, height: 1))
        textField.rightView = rightSpacer
        textField.rightViewMode = .always
    }

    /// Styles an image well (a photo/map picker placeholder) as a card,
    /// replacing ad hoc `.systemGray6`/`.systemGray5` backgrounds so every
    /// image placeholder in the app reads the same way.
    static func styleImageWell(_ imageView: UIImageView) {
        imageView.backgroundColor = .secondarySystemGroupedBackground
        imageView.layer.cornerRadius = cardCornerRadius
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.separator.cgColor
        imageView.clipsToBounds = true
    }
}
