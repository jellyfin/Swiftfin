//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

final class EPGProgramCell: UICollectionViewCell {

    private let chevronView = UIImageView(image: UIImage(systemName: "chevron.down"))
    private let timeLabel = UILabel()
    private let titleLabel = UILabel()

    private var accentColor: UIColor = .clear
    private var baseColor: UIColor = .clear
    private var isCurrent = false

    private(set) var block: ProgramBlock?

    var stickyLeadingOffset: CGFloat = 0 {
        didSet {
            guard oldValue != stickyLeadingOffset else { return }
            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true

        #if os(iOS)
        focusEffect = nil
        #endif

        contentView.layer.cornerRadius = 6
        contentView.layer.borderWidth = 1
        contentView.clipsToBounds = true

        titleLabel.textColor = .label
        timeLabel.textColor = .secondaryLabel
        chevronView.tintColor = .label
        chevronView.contentMode = .scaleAspectFit

        contentView.addSubview(titleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(chevronView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        block: ProgramBlock,
        isCurrent: Bool,
        typeColor: UIColor?
    ) {
        let accent = Defaults[.accentColor]

        self.block = block
        self.isCurrent = isCurrent
        self.accentColor = UIColor(accent)

        if isCurrent {
            baseColor = self.accentColor.withAlphaComponent(0.5)
        } else if let typeColor {
            baseColor = typeColor.withAlphaComponent(0.35)
        } else {
            baseColor = UIColor(Color.secondarySystemFill).withAlphaComponent(0.5)
        }

        let footnote = UIFont.preferredFont(forTextStyle: .footnote)
        let caption = UIFont.preferredFont(forTextStyle: .caption2)

        titleLabel.font = .systemFont(ofSize: footnote.pointSize, weight: isCurrent ? .semibold : .regular)
        timeLabel.font = caption
        chevronView.preferredSymbolConfiguration = .init(font: caption)

        if block.isGroup {
            // swiftlint:disable:next hard_coded_display_string
            titleLabel.text = "\(block.programs.count) \(L10n.programs)"
            timeLabel.text = block.start.formatted(date: .omitted, time: .shortened)
            chevronView.isHidden = false
        } else if let program = block.programs.first {
            titleLabel.text = program.displayTitle
            timeLabel.text = [
                program.startDate?.formatted(date: .omitted, time: .shortened),
                program.endDate?.formatted(date: .omitted, time: .shortened),
            ]
                .compactMap(\.self)
                .joined(separator: " \(String.bullet) ")
            chevronView.isHidden = true
        }

        applyStyle()
        setNeedsLayout()
    }

    private func applyStyle() {
        contentView.backgroundColor = baseColor
        titleLabel.textColor = .label
        timeLabel.textColor = .secondaryLabel
        chevronView.tintColor = .label

        if isFocused {
            contentView.layer.borderWidth = 4
            contentView.layer.borderColor = accentColor.cgColor
        } else {
            contentView.layer.borderWidth = 1
            contentView.layer.borderColor = UIColor(Color.secondarySystemFill).withAlphaComponent(0.5).cgColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let padding: CGFloat = {
            guard UIDevice.isTV else { return 2 }
            return isFocused ? 0 : 4
        }()

        contentView.frame = bounds.insetBy(dx: padding, dy: padding)

        let showsText = bounds.width >= 70
        let showsChevron = showsText && block?.isGroup == true

        titleLabel.isHidden = !showsText
        timeLabel.isHidden = !showsText
        chevronView.isHidden = !showsChevron

        guard showsText else { return }

        let limit = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let titleSize = titleLabel.sizeThatFits(limit)
        let timeSize = timeLabel.sizeThatFits(limit)
        let chevronSize = showsChevron ? chevronView.intrinsicContentSize : .zero

        let textWidth = max(titleSize.width + (showsChevron ? chevronSize.width + 4 : 0), timeSize.width)
        let shift = clamp(
            stickyLeadingOffset - frame.minX,
            min: 0,
            max: max(0, contentView.bounds.width - textWidth - 16)
        )
        let originX = 8 + shift

        titleLabel.frame = CGRect(
            x: originX,
            y: 6,
            width: min(titleSize.width, max(0, contentView.bounds.width - originX - 8)),
            height: titleSize.height
        )

        chevronView.frame = CGRect(
            x: titleLabel.frame.maxX + 4,
            y: titleLabel.frame.midY - chevronSize.height / 2,
            width: chevronSize.width,
            height: chevronSize.height
        )

        timeLabel.frame = CGRect(
            x: originX,
            y: titleLabel.frame.maxY + 2,
            width: min(timeSize.width, max(0, contentView.bounds.width - originX - 8)),
            height: timeSize.height
        )
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        coordinator.addCoordinatedAnimations {
            self.applyStyle()
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
}
