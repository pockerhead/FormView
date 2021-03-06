//
//  ItemProvider.swift
//  CollectionKit
//
//  Created by Luke Zhao on 2018-06-13.
//  Copyright © 2018 lkzhao. All rights reserved.
//

import UIKit

// swiftlint:disable all
public protocol ItemProvider: Provider {
    var canReorderItems: Bool { get }
    
    func view(at: Int) -> UIView
    func update(view: UIView, at: Int)
    
    func didTap(view: UIView, at: Int)
    
    func didBeginLongTapWithProvider(context: LongGestureContext)
    func didLongTapContinue(context: LongGestureContext) -> CGRect?
    func didLongTapCancelled(context: LongGestureContext)
    func didLongTapEnded(context: LongGestureContext)
}

public class LongGestureContext {
    var view: UIView,
    sectionIndex: Int?,
    collectionView: CollectionView,
    locationInCollection: CGPoint,
    previousLocationInCollection: CGPoint?,
    index: Int
    
    var dragProvider: ItemProvider?
    var intersectsCell: CollectionView.CellPath?
    var oldCellFrame: CGRect?
    var lastReorderedIndex: Int?
    
    init(view: UIView,
         collectionView: CollectionView,
         locationInCollection: CGPoint,
         previousLocationInCollection: CGPoint?,
         index: Int) {
        self.view = view
        self.collectionView = collectionView
        self.locationInCollection = locationInCollection
        self.previousLocationInCollection = previousLocationInCollection
        self.index = index
    }
}

public extension ItemProvider {
    var canReorderItems: Bool { false }
    
    func flattenedProvider() -> ItemProvider {
        self
    }
    
    func didBeginLongTapWithProvider(context: LongGestureContext) {}
    func didLongTapContinue(context: LongGestureContext) -> CGRect? { nil }
    func didLongTapCancelled(context: LongGestureContext) {}
    func didLongTapEnded(context: LongGestureContext) {}
}
