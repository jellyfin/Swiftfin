//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

private let nowLineKind = "EPGNowLine"

final class EPGGridLayout: UICollectionViewLayout {

    var contentWidth: CGFloat = 0
    var nowColor: UIColor = .clear
    var nowOffset: CGFloat?
    var rowHeight: CGFloat = 0
    var sectionFrames: [[CGRect]] = []

    private var contentHeight: CGFloat = 0
    private var nowLineAttributes: EPGNowLineAttributes?
    private var sectionAttributes: [[UICollectionViewLayoutAttributes]] = []

    override init() {
        super.init()

        register(EPGNowLineView.self, forDecorationViewOfKind: nowLineKind)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: contentWidth, height: contentHeight)
    }

    override func prepare() {
        contentHeight = CGFloat(sectionFrames.count) * rowHeight

        sectionAttributes = sectionFrames.enumerated().map { section, frames in
            frames.enumerated().map { item, frame in
                let attributes = UICollectionViewLayoutAttributes(
                    forCellWith: IndexPath(item: item, section: section)
                )
                attributes.frame = frame
                return attributes
            }
        }

        if let nowOffset, (0 ... contentWidth).contains(nowOffset) {
            let attributes = EPGNowLineAttributes(
                forDecorationViewOfKind: nowLineKind,
                with: IndexPath(item: 0, section: 0)
            )
            attributes.frame = CGRect(x: nowOffset, y: 0, width: 2, height: contentHeight)
            attributes.zIndex = 100
            attributes.color = nowColor
            nowLineAttributes = attributes
        } else {
            nowLineAttributes = nil
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard rowHeight > 0, sectionAttributes.isNotEmpty else { return nil }

        let rect = rect.insetBy(dx: -600, dy: -rowHeight * 3)

        var result: [UICollectionViewLayoutAttributes] = []

        let firstRow = max(0, Int(rect.minY / rowHeight))
        let lastRow = min(sectionAttributes.count - 1, Int(rect.maxY / rowHeight))

        if firstRow <= lastRow {
            for row in firstRow ... lastRow {
                for attributes in sectionAttributes[row] where attributes.frame.intersects(rect) {
                    result.append(attributes)
                }
            }
        }

        if let nowLineAttributes, nowLineAttributes.frame.intersects(rect) {
            result.append(nowLineAttributes)
        }

        return result
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        sectionAttributes[safe: indexPath.section]?[safe: indexPath.item]
    }

    override func layoutAttributesForDecorationView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        nowLineAttributes
    }
}

private final class EPGNowLineAttributes: UICollectionViewLayoutAttributes {

    var color: UIColor = .clear

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! EPGNowLineAttributes
        copy.color = color
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? EPGNowLineAttributes else { return false }
        return super.isEqual(object) && object.color == color
    }
}

private final class EPGNowLineView: UICollectionReusableView {

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        backgroundColor = (layoutAttributes as? EPGNowLineAttributes)?.color
        isUserInteractionEnabled = false
    }
}
