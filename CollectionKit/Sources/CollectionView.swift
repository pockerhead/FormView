//
//  CollectionKit.swift
//  CollectionKit
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit

// swiftlint:disable all
open class CollectionView: UIScrollView {
    
    public var provider: Provider? {
        didSet { setNeedsReload() }
    }
    
    public var animator: Animator = Animator() {
        didSet { setNeedsReload() }
    }
    
    public private(set) var reloadCount = 0
    public private(set) var needsReload = true
    public private(set) var needsInvalidateLayout = false
    public private(set) var isLoadingCell = false
    public private(set) var isReloading = false
    public var hasReloaded: Bool { return reloadCount > 0 }
    private var feedback = UIImpactFeedbackGenerator(style: .medium)

    lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(tap(sender:)))
        addGestureRecognizer(tap)
        return tap
    }()
    
    lazy var longTapGestureRecognizer: UILongPressGestureRecognizer = {
        let tap = UILongPressGestureRecognizer()
        tap.addTarget(self, action: #selector(longTap(gesture:)))
        return tap
    }()
    
    lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(scrollWhenDragIfNeeded))
        return link
    }()
    
    // visible identifiers for cells on screen
    public private(set) var visibleIndexes: [Int] = []
    public private(set) var visibleCells: [UIView] = []
    public private(set) var visibleIdentifiers: [String] = []
    
    var draggedCell: CellPath?
    var draggedCellOldFrame: CGRect?
    var draggedCellInitialFrame: CGRect?

    var draggedSectionIndex: Int?
    var previousLocation: CGPoint?
    var dragProvider: ItemProvider?
    var lastReorderedIndex: Int?
    var isInProcessDragging: Bool = false
    
    struct CellPath {
        var cell: UIView
        var index: Int
    }
    
    public private(set) var lastLoadBounds: CGRect = .zero
    public private(set) var contentOffsetChange: CGPoint = .zero
    
    lazy var flattenedProvider: ItemProvider = EmptyCollectionProvider()
    var identifierCache: [Int: String] = [:]
    
    public convenience init(provider: Provider) {
        self.init()
        self.provider = provider
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        CollectionViewManager.shared.register(collectionView: self)
        _ = tapGestureRecognizer
        _ = longTapGestureRecognizer
        displayLink.add(to: .main, forMode: .default) // доделать!
    }
    
    deinit {
        displayLink.remove(from: .main, forMode: .default)
    }
    
    @objc func scrollWhenDragIfNeeded() {
        guard isInProcessDragging, let cell = draggedCell?.cell,
            let selfWindowFrame = superview?.convert(frame, to: nil),
            let cellWindowFrame = cell.superview?.convert(cell.frame, to: nil),
            let provider = dragProvider as? FormViewProvider else { return }
        let maxManualOffset: CGFloat = 5
        if provider.layout is FlowLayout || (provider.layout as? WrapperLayout)?.rootLayout is FlowLayout {
            if cellWindowFrame.maxY > selfWindowFrame.maxY {
                let x = contentOffset.x
                var y = contentOffset.y
                let offset = (cellWindowFrame.maxY - selfWindowFrame.maxY).clamp(0, maxManualOffset)
                y = (y + offset).clamp(0, (contentSize.height - bounds.height))
                let increasedContentOffset = CGPoint(x: x, y: y)
                setContentOffset(increasedContentOffset, animated: false)
                DispatchQueue.main.async {
                    self.draggedCell?.cell.center = self.longTapGestureRecognizer.location(in: self)
                    self.detectMovingCell()
                }
            } else if cellWindowFrame.origin.y < selfWindowFrame.origin.y {
                let x = contentOffset.x
                var y = contentOffset.y
                let offset = abs(cellWindowFrame.origin.y - selfWindowFrame.origin.y).clamp(0, maxManualOffset)
                y = (y - offset).clamp(0, (contentSize.height - bounds.height))
                let increasedContentOffset = CGPoint(x: x, y: y)
                setContentOffset(increasedContentOffset, animated: false)
                DispatchQueue.main.async {
                    self.draggedCell?.cell.center = self.longTapGestureRecognizer.location(in: self)
                    self.detectMovingCell()
                }
            }
        } else if provider.layout is RowLayout || (provider.layout as? WrapperLayout)?.rootLayout is RowLayout {
            if cellWindowFrame.maxX > selfWindowFrame.maxX {
                var x = contentOffset.x
                let y = contentOffset.y
                let offset = (cellWindowFrame.maxX - selfWindowFrame.maxX).clamp(0, maxManualOffset)
                x = (x + offset).clamp(0, (contentSize.width - bounds.width))
                let increasedContentOffset = CGPoint(x: x, y: y)
                setContentOffset(increasedContentOffset, animated: false)
                DispatchQueue.main.async {
                    self.draggedCell?.cell.center = self.longTapGestureRecognizer.location(in: self)
                    self.detectMovingCell()
                }
            } else if cellWindowFrame.origin.x < selfWindowFrame.origin.x {
                var x = contentOffset.x
                let y = contentOffset.y
                let offset = abs(cellWindowFrame.origin.x - selfWindowFrame.origin.x).clamp(0, maxManualOffset)
                x = (x - offset).clamp(0, (contentSize.width - bounds.width))
                let increasedContentOffset = CGPoint(x: x, y: y)
                setContentOffset(increasedContentOffset, animated: false)
                DispatchQueue.main.async {
                    self.draggedCell?.cell.center = self.longTapGestureRecognizer.location(in: self)
                    self.detectMovingCell()
                }
            }
        }
    }
    
    func detectMovingCell() {
        guard let draggedCell = draggedCell?.cell,
            let draggedCellIndex = self.draggedCell?.index else { return }
        let context = LongGestureContext(view: draggedCell,
                                         collectionView: self,
                                         locationInCollection: longTapGestureRecognizer.location(in: self),
                                         previousLocationInCollection: previousLocation,
                                         index: draggedCellIndex)
        context.oldCellFrame = draggedCellOldFrame
        context.lastReorderedIndex = lastReorderedIndex
        bringSubviewToFront(draggedCell)
        for (cell, index) in zip(visibleCells, visibleIndexes).reversed() {
            if cell === draggedCell { continue }
            if cell.frame.intersects(draggedCell.frame) {
                guard let index = (flattenedProvider as? FlattenedProvider)?.indexPath(index).1 else { return }
                context.intersectsCell = CellPath(cell: cell, index: index)
            }
        }
        let newOldRect = dragProvider?.didLongTapContinue(context: context)
        if let lnewOldRect = newOldRect {
            feedback.impactOccurred()
            draggedCellOldFrame = lnewOldRect
            if lnewOldRect == draggedCellInitialFrame ?? .zero {
                lastReorderedIndex = context.index
            } else {
                lastReorderedIndex = context.intersectsCell?.index
            }
        }
    }
    
    func removeAllLongPressRecognizers() {
        gestureRecognizers?.forEach { rec in
            guard rec.className.contains("LongPress") ||
                rec.className.contains("UIScrollViewDelayedTouchesBegan") else { return }
            removeGestureRecognizer(rec)
        }
    }
    
    @IBAction func tap(sender: UITapGestureRecognizer) {
        for (cell, index) in zip(visibleCells, visibleIndexes).reversed() {
            if cell.point(inside: sender.location(in: cell), with: nil) {
                flattenedProvider.didTap(view: cell, at: index)
                return
            }
        }
    }
    
    @IBAction func longTap(gesture: UILongPressGestureRecognizer) {
        guard let provider = (provider as? ItemProvider), provider.canReorderItems == true else { return }
        if gesture.state == .began {
            becomeFirstResponder()
            for (cell, index) in zip(visibleCells, visibleIndexes).reversed() {
                if cell.point(inside: gesture.location(in: cell), with: nil) {
                    feedback.impactOccurred()
                    draggedCellOldFrame = cell.frame
                    draggedCellInitialFrame = draggedCellOldFrame
                    bringSubviewToFront(cell)
                    cell.alpha = 0.7
                    UIView.animate(withDuration: 0.2) {
                        cell.center = gesture.location(in: self)
                    }
                    let interIndexPath = (flattenedProvider as? FlattenedProvider)?.indexPath(index)
                    let interProviderIndex = interIndexPath?.1 ?? index
                    self.draggedSectionIndex = (interIndexPath?.0 ?? 1) - 1
                    let context = LongGestureContext(view: cell,
                                                     collectionView: self,
                                                     locationInCollection: gesture.location(in: self),
                                                     previousLocationInCollection: previousLocation,
                                                     index: interProviderIndex)
                    flattenedProvider.didBeginLongTapWithProvider(context: context)
                    if let dragProvider = context.dragProvider as? FormViewHeaderProvider,
                        interProviderIndex == 0,
                        dragProvider.sections.have(self.draggedSectionIndex ?? 0) {
                        self.dragProvider = dragProvider.sections[self.draggedSectionIndex ?? 0] as? ItemProvider
                    } else {
                        dragProvider = context.dragProvider
                    }
                    draggedCell = CellPath(cell: cell, index: interProviderIndex)
                    isInProcessDragging = true
                }
            }
        } else {
            guard let draggedCell = draggedCell?.cell,
                let draggedCellIndex = self.draggedCell?.index else { return }
            let context = LongGestureContext(view: draggedCell,
                                             collectionView: self,
                                             locationInCollection: gesture.location(in: self),
                                             previousLocationInCollection: previousLocation,
                                             index: draggedCellIndex)
            context.oldCellFrame = draggedCellOldFrame
            context.lastReorderedIndex = lastReorderedIndex
            for (cell, index) in zip(visibleCells, visibleIndexes).reversed() {
                if cell === draggedCell { continue }
                if cell.frame.intersects(draggedCell.frame) {
                    guard let index = (flattenedProvider as? FlattenedProvider)?.indexPath(index).1 else { return }
                    context.intersectsCell = CellPath(cell: cell, index: index)
                }
            }
            switch gesture.state {
            case .changed:
                let newOldRect = dragProvider?.didLongTapContinue(context: context)
                if let lnewOldRect = newOldRect {
                    draggedCellOldFrame = lnewOldRect
                    feedback.impactOccurred()
                    if lnewOldRect == draggedCellInitialFrame ?? .zero {
                        lastReorderedIndex = context.index
                    } else {
                        if lastReorderedIndex == context.intersectsCell?.index {
                            let isVerticalScroll = (dragProvider as? LayoutableProvider)?.layout is FlowLayout
                            let draggedToBegin: Bool
                            if isVerticalScroll {
                                draggedToBegin = context.locationInCollection.y < previousLocation?.y ?? 0
                            } else {
                                draggedToBegin = context.locationInCollection.x < previousLocation?.x ?? 0
                            }
                            if draggedToBegin {
                                lastReorderedIndex = ((context.intersectsCell?.index ?? 0) - 1)
                            } else {
                                lastReorderedIndex = ((context.intersectsCell?.index ?? 0) + 1)
                            }
                        } else {
                            lastReorderedIndex = context.intersectsCell?.index
                        }
                    }
                }
            case .cancelled:
                clearDrag {[weak self] in
                    guard let self = self else { return }
                    self.dragProvider?.didLongTapCancelled(context: context)
                }
            case .ended:
                clearDrag {[weak self] in
                    guard let self = self else { return }
                    self.dragProvider?.didLongTapEnded(context: context)
                }
            default:
                break
            }
        }
        previousLocation = gesture.location(in: self)
    }
    
    private func clearDrag(closure: (() -> Void)?) {
        self.resignFirstResponder()
        self.isInProcessDragging = false
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.3, animations: {[weak self] in
                guard let self = self else { return }
                self.draggedCell?.cell.frame = self.draggedCellOldFrame ?? .zero
                self.draggedCell?.cell.alpha = 1
            }) { _ in
                self.feedback.impactOccurred()
                self.draggedCell?.cell.removeFromSuperview()
                closure?()
                self.draggedCell = nil
                self.draggedCellOldFrame = nil
                self.draggedSectionIndex = nil
                self.previousLocation = nil
                self.dragProvider = nil
                self.lastReorderedIndex = nil
                self.dragProvider = nil
                DispatchQueue.main.async {[weak self] in
                    guard let self = self else { return }
                    self.reloadData()
                }
            }
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if needsReload {
            reloadData()
        } else if needsInvalidateLayout || bounds.size != lastLoadBounds.size {
            invalidateLayout()
        } else if bounds != lastLoadBounds {
            loadCells()
        }
    }
    
    public func setNeedsReload() {
        needsReload = true
        setNeedsLayout()
    }
    
    public func setNeedsInvalidateLayout() {
        needsInvalidateLayout = true
        setNeedsLayout()
    }
    
    public func invalidateLayout() {
        guard !isLoadingCell && !isReloading && hasReloaded else { return }
        flattenedProvider.layout(collectionSize: innerSize)
        contentSize = flattenedProvider.contentSize
        needsInvalidateLayout = false
        loadCells()
    }
    
    /*
     * Update visibleCells & visibleIndexes according to scrollView's visibleFrame
     * load cells that move into the visibleFrame and recycles them when
     * they move out of the visibleFrame.
     */
    func loadCells() {
        guard !isLoadingCell && !isReloading && hasReloaded else { return }
        isLoadingCell = true
        
        _loadCells(forceReload: false)
        if !isInProcessDragging {
            for (cell, index) in zip(visibleCells, visibleIndexes) {
                let animator = cell.currentCollectionAnimator ?? self.animator
                animator.update(collectionView: self, view: cell, at: index, frame: flattenedProvider.frame(at: index))
            }
        }
        
        lastLoadBounds = bounds
        isLoadingCell = false
    }
    
    // reload all frames. will automatically diff insertion & deletion
    public func reloadData(contentOffsetAdjustFn: (() -> CGPoint)? = nil) {
        guard !isReloading && !isInProcessDragging else { return }
        provider?.willReload()
//        if (provider as? ItemProvider)?.canReorderItems {
//            addGestureRecognizer(longTapGestureRecognizer)
//        } else {
//            removeGestureRecognizer(longTapGestureRecognizer)
//        }
        flattenedProvider = (provider ?? EmptyCollectionProvider()).flattenedProvider()
        isReloading = true
        
        flattenedProvider.layout(collectionSize: innerSize)
        let oldContentOffset = contentOffset
        contentSize = flattenedProvider.contentSize
        if let offset = contentOffsetAdjustFn?() {
            contentOffset = offset
        }
        contentOffsetChange = contentOffset - oldContentOffset
        
        let oldVisibleCells = Set(visibleCells)
        _loadCells(forceReload: true)
        
        for (cell, index) in zip(visibleCells, visibleIndexes) {
            cell.currentCollectionAnimator = cell.collectionAnimator ?? flattenedProvider.animator(at: index)
            let animator = cell.currentCollectionAnimator ?? self.animator
            if oldVisibleCells.contains(cell) {
                // cell was on screen before reload, need to update the view.
                flattenedProvider.update(view: cell, at: index)
                animator.shift(collectionView: self, delta: contentOffsetChange, view: cell,
                               at: index, frame: flattenedProvider.frame(at: index))
            }
            animator.update(collectionView: self, view: cell,
                            at: index, frame: flattenedProvider.frame(at: index))
        }
        
        lastLoadBounds = bounds
        needsInvalidateLayout = false
        needsReload = false
        reloadCount += 1
        isReloading = false
        flattenedProvider.didReload()
    }
    
    private func _loadCells(forceReload: Bool) {
        let newIndexes = flattenedProvider.visibleIndexes(visibleFrame: visibleFrame)
        
        // optimization: we assume that corresponding identifier for each index doesnt change unless forceReload is true.
        guard forceReload ||
            newIndexes.last != visibleIndexes.last ||
            newIndexes != visibleIndexes else {
                return
        }
        
        // during reloadData we clear all cache
        if forceReload {
            identifierCache.removeAll()
        }
        
        var newIdentifierSet = Set<String>()
        let newIdentifiers: [String] = newIndexes.map { index in
            if let identifier = identifierCache[index] {
                newIdentifierSet.insert(identifier)
                return identifier
            } else {
                let identifier = flattenedProvider.identifier(at: index)
                
                // avoid identifier collision
                var finalIdentifier = identifier
                var count = 1
                while newIdentifierSet.contains(finalIdentifier) {
                    finalIdentifier = identifier + "(\(count))"
                    count += 1
                }
                newIdentifierSet.insert(finalIdentifier)
                identifierCache[index] = finalIdentifier
                return finalIdentifier
            }
        }
        
        var existingIdentifierToCellMap: [String: UIView] = [:]
        
        // 1st pass, delete all removed cells
        for (index, identifier) in visibleIdentifiers.enumerated() {
            let cell = visibleCells[index]
            if !newIdentifierSet.contains(identifier) && cell !== draggedCell?.cell {
                (cell.currentCollectionAnimator ?? animator)?.delete(collectionView: self, view: cell)
            } else {
                existingIdentifierToCellMap[identifier] = cell
            }
        }
        
        // 2nd pass, insert new views
        let newCells: [UIView] = zip(newIdentifiers, newIndexes).map { identifier, index in
            if let existingCell = existingIdentifierToCellMap[identifier] {
                return existingCell
            } else {
                return _generateCell(index: index)
            }
        }
        
        for (index, cell) in newCells.enumerated() where subviews.get(index) !== cell {
            insertSubview(cell, at: index)
        }
        
        visibleIndexes = newIndexes
        visibleIdentifiers = newIdentifiers
        visibleCells = newCells
    }
    
    private func _generateCell(index: Int) -> UIView {
        let cell = flattenedProvider.view(at: index)
        let frame = flattenedProvider.frame(at: index)
        cell.bounds.size = frame.bounds.size
        cell.center = frame.center
        cell.currentCollectionAnimator = cell.collectionAnimator ?? flattenedProvider.animator(at: index)
        let animator = cell.currentCollectionAnimator ?? self.animator
        animator.insert(collectionView: self, view: cell, at: index, frame: flattenedProvider.frame(at: index))
        return cell
    }
}

extension CollectionView {
    public func indexForCell(at point: CGPoint) -> Int? {
        for (index, cell) in zip(visibleIndexes, visibleCells) {
            if cell.point(inside: cell.convert(point, from: self), with: nil) {
                return index
            }
        }
        return nil
    }
    
    public func index(for cell: UIView) -> Int? {
        if let position = visibleCells.firstIndex(of: cell) {
            return visibleIndexes[position]
        }
        return nil
    }
    
    public func cell(at index: Int) -> UIView? {
        if let position = visibleIndexes.firstIndex(of: index) {
            return visibleCells[position]
        }
        return nil
    }
}
