//
//  FormViewHeaderProvider.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
// swiftlint:disable all

import UIKit

open class FormViewHeaderProvider:
SectionProvider, ItemProvider, LayoutableProvider, CollectionReloadable {
    
    public typealias HeaderViewSource = FormViewViewSource
    public typealias HeaderSizeSource = FormViewSizeSource
    
    open var identifier: String?
    
    public var canReorderItems: Bool { _canReorderItems }
    
    private var _canReorderItems: Bool = false
    open var sections: [Provider] {
        didSet { setNeedsReload() }
    }
    
    open var animator: Animator? {
        didSet { setNeedsReload() }
    }
    
    var headerData: [ViewModelWithViewClass?]
    
    open var headerViewSource: HeaderViewSource = FormViewViewSource() {
        didSet { setNeedsReload() }
    }
    var didReloadClosure: (() -> Void)?
    
    open var headerSizeSource: HeaderSizeSource = FormViewSizeSource() {
        didSet { setNeedsInvalidateLayout() }
    }
    
    open var layout: Layout {
        get { return stickyLayout.rootLayout }
        set {
            stickyLayout.rootLayout = newValue
            setNeedsInvalidateLayout()
        }
    }
    
    var scrollDirection: UICollectionView.ScrollDirection
    
    open var isSticky = true {
        didSet {
            if isSticky {
                stickyLayout.isStickyFn = { $0 % 2 == 0 }
            } else {
                stickyLayout.isStickyFn = { _ in false }
            }
            setNeedsReload()
        }
    }
    
    open var tapHandler: TapHandler?
    
    public typealias TapHandler = (TapContext) -> Void
    
    public struct TapContext {
        public let view: UIView
        public let index: Int
        public let section: Provider
    }
    
    private var stickyLayout: StickyLayout
    public var internalLayout: Layout { return stickyLayout }
    
    init(identifier: String? = "RootProvider",
         layout: Layout = FlowLayout(),
         animator: Animator? = AnimatedReloadAnimator(),
         sections: [FormSection] = []) {
        self.animator = animator
        self.stickyLayout = StickyLayout(rootLayout: layout)
        self._canReorderItems = sections.reduce(false, { $0 || $1.haveDidReloadSectionsClosure })
        self.sections = sections.map { $0.provider }
        self.headerData = sections.map { $0.headerData }
        self.identifier = identifier
        self.tapHandler = nil
        self.scrollDirection = layout is RowLayout ? .horizontal : .vertical
        if let layout = layout as? WrapperLayout {
            self.scrollDirection = layout.rootLayout is RowLayout ? .horizontal : .vertical
        }
    }
    
    open var numberOfItems: Int {
        return sections.count * 2
    }
    
    open func section(at: Int) -> Provider? {
        if at % 2 == 0 {
            return nil
        } else {
            return sections[at / 2]
        }
    }
    
    @discardableResult
    func bindReload(_ didReload: (() -> Void)?) -> FormViewHeaderProvider {
        self.didReloadClosure = didReload
        return self
    }
    
    open func identifier(at: Int) -> String {
        let sectionIdentifier = sections[at / 2].identifier ?? "\(at)"
        if at % 2 == 0 {
            return sectionIdentifier + "-header"
        } else {
            return sectionIdentifier
        }
    }
    
    open func layoutContext(collectionSize: CGSize) -> LayoutContext {
        return ComposedHeaderProviderLayoutContext(
            collectionSize: collectionSize,
            sections: sections,
            headerSizeSource: headerSizeSource,
            headerViewSource: headerViewSource,
            headerProvider: self,
            scrollDirection: scrollDirection
        )
    }
    
    open func animator(at: Int) -> Animator? {
        return animator
    }
    
    open func view(at: Int) -> UIView {
        let index = at / 2
        guard let data = headerData[index] else { return UIView() }
        return headerViewSource.view(data: data, index: index)
    }
    
    open func update(view: UIView, at: Int) {
        let index = at / 2
        guard let data = headerData[index] else { return }
        headerViewSource.update(view: view as! ViewModelConfigurable, data: data, index: index)
    }
    
    open func didTap(view: UIView, at: Int) {
        if let tapHandler = tapHandler {
            let index = at / 2
            let context = TapContext(view: view, index: index, section: sections[index])
            tapHandler(context)
        }
    }
    
    open func willReload() {
        for section in sections {
            section.willReload()
        }
    }
    
    open func didReload() {
        for section in sections {
            section.didReload()
        }
        didReloadClosure?()
    }
    
    // MARK: private stuff
    open func hasReloadable(_ reloadable: CollectionReloadable) -> Bool {
        return reloadable === self || reloadable === headerSizeSource
            || sections.contains(where: { $0.hasReloadable(reloadable) })
    }
    
    open func flattenedProvider() -> ItemProvider {
        return FlattenedProvider(provider: self)
    }
    
    struct ComposedHeaderProviderLayoutContext: LayoutContext {
        var collectionSize: CGSize
        var sections: [Provider]
        var headerSizeSource: HeaderSizeSource
        var headerViewSource: HeaderViewSource
        weak var headerProvider: FormViewHeaderProvider?
        var scrollDirection: UICollectionView.ScrollDirection
        
        var numberOfItems: Int {
            return sections.count * 2
        }
        func data(at: Int) -> Any {
            let arrayIndex = at / 2
            if at % 2 == 0 {
                return headerProvider?.headerData[arrayIndex] as Any
            } else {
                return sections[arrayIndex]
            }
        }
        
        func headerData(at: Int) -> ViewModelWithViewClass? {
            headerProvider?.headerData[at]
        }
        func identifier(at: Int) -> String {
            let sectionIdentifier = sections[at / 2].identifier ?? "\(at)"
            if at % 2 == 0 {
                return sectionIdentifier + "-header"
            } else {
                return sectionIdentifier
            }
        }
        func size(at index: Int, collectionSize: CGSize) -> CGSize {
            let arrayIndex = index / 2
            if index % 2 == 0 {
                let opdata = headerData(at: arrayIndex)
                guard let data = opdata else { return .zero }
                let opdummy = headerViewSource.getDummyView(data: data) as? ViewModelConfigurable
                guard let dummyView = opdummy else { return .zero }
                return headerSizeSource.size(at: arrayIndex,
                                             data: data,
                                             collectionSize: collectionSize,
                                             dummyView: dummyView,
                                             direction: scrollDirection)
            } else {
                sections[arrayIndex].layout(collectionSize: collectionSize)
                return sections[arrayIndex].contentSize
            }
        }
    }
}

