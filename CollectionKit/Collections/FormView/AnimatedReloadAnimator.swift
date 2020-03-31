//
//  AnyHeaderProvider.swift
//  SmartStaff
//
//  Created by artem on 27.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//

import UIKit

// swiftlint:disable all
open class AnimatedReloadAnimator: Animator {
    static let defaultEntryTransform: CATransform3D = CATransform3DTranslate(CATransform3DScale(CATransform3DIdentity, 0.8, 0.8, 1), 0, 0, -1)
    static let fancyEntryTransform: CATransform3D = {
        var trans = CATransform3DIdentity
        trans.m34 = -1 / 500
        return CATransform3DScale(CATransform3DRotate(CATransform3DTranslate(trans, 0, -50, -100), 0.5, 1, 0, 0), 0.8, 0.8, 1)
    }()
    
    let entryTransform: CATransform3D
    
    init(entryTransform: CATransform3D = defaultEntryTransform) {
        self.entryTransform = entryTransform
        super.init()
    }
    
    override open func delete(collectionView: CollectionView, view: UIView) {
        if collectionView.isReloading, collectionView.bounds.intersects(view.frame) {
            let initialTransform = view.transform
            UIView.animate(withDuration: 0.25, animations: {
                view.layer.transform = self.entryTransform
                view.alpha = 0
            }, completion: { _ in
                if !collectionView.visibleCells.contains(view) {
                    view.recycleForCollectionKitReuse()
                    view.transform = initialTransform
                    view.alpha = 1
                }
            })
        } else {
            view.recycleForCollectionKitReuse()
        }
    }
    
    override open func insert(collectionView: CollectionView, view: UIView, at: Int, frame: CGRect) {
        view.bounds = frame.bounds
        view.center = frame.center
        if collectionView.isReloading, collectionView.hasReloaded, collectionView.bounds.intersects(frame) {
            let offsetTime: TimeInterval = TimeInterval(frame.origin.distance(collectionView.contentOffset) / 3000)
            let initialTransform = view.transform
            view.layer.transform = entryTransform
            view.alpha = 0
            UIView.animate(withDuration: 0.5, delay: offsetTime, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                view.transform = initialTransform
                view.alpha = 1
            })
        } else {
            view.alpha = 1
        }
    }
    
    override open func update(collectionView: CollectionView, view: UIView, at: Int, frame: CGRect) {
        let offset = abs(collectionView.contentOffset.y + collectionView.contentInset.top + collectionView.safeAreaInsets.top)
        let initialTransform = view.transform
        if (view as? StickyHeaderView)?.isExpanded == true && frame.origin.y == offset {
            super.update(collectionView: collectionView, view: view, at: at, frame: frame)
            return
        }
        if view.center != frame.center {
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.layoutSubviews], animations: {
                view.center = frame.center
            }, completion: nil)
        }
        if view.bounds.size != frame.bounds.size {
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [.layoutSubviews], animations: {
                view.bounds.size = frame.bounds.size
            }, completion: nil)
        }
        if view.alpha != 1 || view.transform != .identity || view.transform != initialTransform {
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.transform = initialTransform
                view.alpha = 1
            }, completion: nil)
        }
    }
}

protocol StickyHeaderView {
    var isExpanded: Bool { get }
}

extension StickyHeaderView {
    var isExpanded: Bool { true }
}
