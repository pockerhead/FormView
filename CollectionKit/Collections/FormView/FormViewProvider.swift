//
//  FormViewProvider.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
// swiftlint:disable all
import UIKit


final class FormViewProvider: ItemProvider, CollectionReloadable, LayoutableProvider {
    var identifier: String?
    var dataSource: FormViewDataSource { didSet { setNeedsReload() } }
    var viewSource: FormViewViewSource { didSet { setNeedsReload() } }
    var sizeSource: FormViewSizeSource { didSet { setNeedsInvalidateLayout() } }
    var layout: Layout { didSet { setNeedsInvalidateLayout() } }
    var animator: Animator? { didSet { setNeedsReload() } }
    var tapHandler: TapHandler?
    var didReloadClosure: (() -> Void)?
    var scrollDirection: UICollectionView.ScrollDirection
    var didReorderItemsClosure: ((Int, Int) -> Void)?
    public typealias TapHandler = (TapContext) -> Void
    
    public struct TapContext {
        public let view: UIView
        public let index: Int
        public let dataSource: FormViewDataSource
        
        public var data: ViewModelWithViewClass? {
            return dataSource.data(at: index)
        }
        
        public func setNeedsReload() {
            dataSource.setNeedsReload()
        }
    }
    
    public init(identifier: String? = nil,
                dataSource: FormViewDataSource,
                viewSource: FormViewViewSource = FormViewViewSource(),
                sizeSource: FormViewSizeSource = FormViewSizeSource(),
                didReorderItemsClosure: ((Int, Int) -> Void)?,
                layout: Layout = FlowLayout(),
                animator: Animator? = AnimatedReloadAnimator(),
                tapHandler: TapHandler? = nil) {
        self.dataSource = dataSource
        self.viewSource = viewSource
        self.layout = layout
        self.didReorderItemsClosure = didReorderItemsClosure
        self.sizeSource = sizeSource
        self.animator = animator
        self.tapHandler = tapHandler
        self.identifier = identifier
        self.scrollDirection = layout is RowLayout ? .horizontal : .vertical
        if let layout = layout as? WrapperLayout {
            self.scrollDirection = layout.rootLayout is RowLayout ? .horizontal : .vertical
        }
    }
    
    func didReload() {
        didReloadClosure?()
    }
    
    @discardableResult
    func bindReload(_ didReload: (() -> Void)?) -> FormViewProvider {
        self.didReloadClosure = didReload
        return self
    }
    
    var numberOfItems: Int {
        return dataSource.numberOfItems
    }
    func view(at: Int) -> UIView {
        return viewSource.view(data: dataSource.data(at: at), index: at)
    }
    func update(view: UIView, at: Int) {
        viewSource.update(view: view as! ViewModelConfigurable, data: dataSource.data(at: at), index: at)
    }
    func identifier(at: Int) -> String {
        return dataSource.identifier(at: at)
    }
    func layoutContext(collectionSize: CGSize) -> LayoutContext {
        return BasicProviderLayoutContext(collectionSize: collectionSize,
                                          dataSource: dataSource,
                                          viewSource: viewSource,
                                          sizeSource: sizeSource,
                                          scrollDirection: scrollDirection)
    }
    func animator(at: Int) -> Animator? {
        return animator
    }
    func didTap(view: UIView, at: Int) {
        if let tapHandler = tapHandler {
            let context = TapContext(view: view as! ViewModelConfigurable, index: at, dataSource: dataSource)
            tapHandler(context)
        }
    }
    
    func didLongTapContinue(context: LongGestureContext) -> CGRect? {
        context.view.center = context.locationInCollection
        guard let intersectsView = context.intersectsCell?.cell,
            let intersectsFrame = context.intersectsCell?.cell.frame,
            let intersectsIndex = context.intersectsCell?.index,
            let previousLocation = context.previousLocationInCollection,
            let oldFrame = context.oldCellFrame else { return nil }
        let draggedFrame = context.view.frame
        let isVerticalScroll = scrollDirection == .vertical
        let draggedToBegin: Bool
        if isVerticalScroll {
            draggedToBegin = context.locationInCollection.y < previousLocation.y
        } else {
            draggedToBegin = context.locationInCollection.x < previousLocation.x
        }
        let intersectsStruct = Distance(x1: (isVerticalScroll
            ? intersectsFrame.center.y
            : intersectsFrame.center.x) - 20,
                                        x2: (isVerticalScroll
                                            ? intersectsFrame.center.y
                                            : intersectsFrame.center.x) + 20)
        let maxConstant = isVerticalScroll ? draggedFrame.maxY : draggedFrame.maxX
        let intersectsCenterOnTop = draggedToBegin == false && intersectsStruct.contains(x: maxConstant)
        let minConstant = isVerticalScroll ? draggedFrame.origin.y : draggedFrame.origin.x
        let interesctsCenterOnBottom = draggedToBegin == true && intersectsStruct.contains(x: minConstant)
        let needUpdateFrames = intersectsCenterOnTop || interesctsCenterOnBottom
        if needUpdateFrames {
            var newIntersectsFrame = intersectsFrame
            if isVerticalScroll {
                newIntersectsFrame.origin.y = oldFrame.origin.y
            } else {
                newIntersectsFrame.origin.x = oldFrame.origin.x
            }
            animator?.update(collectionView: context.collectionView, view: intersectsView, at: Int(intersectsIndex), frame: newIntersectsFrame)
            return intersectsFrame
        }
        return nil
    }
    
    func didLongTapEnded(context: LongGestureContext) {
        guard let finalIndex = context.lastReorderedIndex else {
            return
        }
        didReorderItemsClosure?(context.index, finalIndex)
    }
    
    func hasReloadable(_ reloadable: CollectionReloadable) -> Bool {
        return reloadable === self || reloadable === dataSource || reloadable === sizeSource
    }

    struct BasicProviderLayoutContext: LayoutContext {
        var collectionSize: CGSize
        var dataSource: FormViewDataSource
        var viewSource: FormViewViewSource
        var sizeSource: FormViewSizeSource
        var scrollDirection: UICollectionView.ScrollDirection
        
        var numberOfItems: Int {
            return dataSource.numberOfItems
        }
        func data(at: Int) -> Any {
            return dataSource.data(at: at)!
        }
        func identifier(at: Int) -> String {
            return dataSource.identifier(at: at)
        }
        func size(at index: Int, collectionSize: CGSize) -> CGSize {
            let data = dataSource.data(at: index)
            let dummyView = viewSource.getDummyView(data: data) as! ViewModelConfigurable
            return sizeSource.size(at: index,
                                   data: data,
                                   collectionSize: collectionSize,
                                   dummyView: dummyView,
                                   direction: scrollDirection)
        }
    }
}

struct Distance {
    var x1: CGFloat
    var x2: CGFloat
    
    func contains(x: CGFloat) -> Bool {
        return x > x1 && x < x2
    }
}
