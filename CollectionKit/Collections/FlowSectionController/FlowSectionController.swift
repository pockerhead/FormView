//
//  FlowSectionController.swift
//  SmartStaff
//
//  Created by artem on 20.02.2020.
//  Copyright © 2020 DIT. All rights reserved.
//

import Foundation
import IGListKit

// swiftlint:disable line_length
class FlowSectionController: ListSectionController, ListSupplementaryViewSource {
    
    // MARK: Properties
    
    private var dataSource: [ViewModelWithViewClass?]
    
    public func setDataSource(_ dataSource: [ViewModelWithViewClass?]) {
        self.dataSource = dataSource
        collectionContext?.performBatch(animated: true, updates: { context in
            context.reload(in: self, at: IndexSet(integersIn: (0...dataSource.count - 1)))
        }, completion: nil)
    }
    
    private var reuseManager: [String: UIView] = [:]
    
    private var tapAction: ((FlowSectionController?, Int) -> Void)?
    private var dummyViewClass: ViewModelConfigurable.Type?
    
    private var scrollDirection: UICollectionView.ScrollDirection = .vertical
   
    private var headerDataSource: ViewModelWithViewClass?
    private var headerHeight: CGFloat?
    
    // MARK: Initialization
    
    init(dataSource: [ViewModelWithViewClass?],
         headerDataSource: ViewModelWithViewClass? = nil,
         headerHeight: CGFloat? = nil,
         dummyViewClass: ViewModelConfigurable.Type? = nil,
         inset: UIEdgeInsets = .zero,
         spacing: CGFloat = 8,
         tapAction: ((FlowSectionController?, Int) -> Void)? = nil,
         scrollDirection: UICollectionView.ScrollDirection = .vertical) {
        self.dataSource = dataSource
        self.headerDataSource = headerDataSource
        self.dummyViewClass = dummyViewClass
        self.tapAction = tapAction
        self.headerHeight = headerHeight
        self.scrollDirection = scrollDirection
        super.init()
        self.inset = inset
        minimumInteritemSpacing = spacing
        minimumLineSpacing = spacing
        supplementaryViewSource = self
    }
    
    // MARK: ListSectionController
    
    override func numberOfItems() -> Int {
        dataSource.count
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let context = collectionContext else {
            return UICollectionViewCell()
        }
        return getConfiguredViewForModel(with: context, at: index)
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        guard
            let context = collectionContext
            else {
                return .zero
        }
        var width = context.containerSize.width - inset.left - inset.right
        var height = context.containerSize.height - inset.top - inset.bottom
        let dummyCell = getDummyViewForModel(with: context, at: index)
        dummyCell.frame.size.width = width
        dummyCell.frame.size.height = height
        switch scrollDirection {
        case .vertical:
            let targetSize = CGSize(width: width, height: .greatestFiniteMagnitude)
            let dummySize = dummyCell.systemLayoutSizeFitting(targetSize,
                                                              withHorizontalFittingPriority: .required,
                                                              verticalFittingPriority: .fittingSizeLevel)
            height = dummySize.height
        case .horizontal:
            let targetSize = CGSize(width: .greatestFiniteMagnitude, height: height)
            let dummySize = dummyCell.systemLayoutSizeFitting(targetSize,
                                                              withHorizontalFittingPriority: .fittingSizeLevel,
                                                              verticalFittingPriority: .required)
            width = dummySize.width
        @unknown default:
            fatalError("Incorrect scroll direction!")
        }
        
        return CGSize(width: width, height: height)
    }
    
    override func didSelectItem(at index: Int) {
        tapAction?(self, index)
    }
    
    // MARK: ListSupplementaryViewSource
    
    func supportedElementKinds() -> [String] {
        [UICollectionView.elementKindSectionHeader]
    }
    
    func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
        guard headerDataSource != nil,
            let context = collectionContext else { return UICollectionReusableView() }
        return getConfiguredHeaderForModel(with: context, at: index)
    }
    
    func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
        guard headerDataSource != nil,
            let context = collectionContext else { return .zero }
        let width = context.containerSize.width
        if let headerHeight = headerHeight {
            return CGSize(width: width, height: headerHeight)
        }
        let view = getConfiguredHeaderForModel(with: context, at: index)
        view.frame.size.width = width
        let targetSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        let dummySize = view.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        let height = dummySize.height
        return CGSize(width: width, height: height)
    }
}

// MARK: Private

extension FlowSectionController {
    
    private func getConfiguredViewForModel(with context: ListCollectionContext,
                                           at index: Int) -> UICollectionViewCell {
        var opType: ViewModelConfigurable.Type?
        let item = dataSource[index]
        if let item = item {
            opType = item.viewClass()
        } else if let dummyViewClass = self.dummyViewClass {
            opType = dummyViewClass
        }
        guard let type = opType,
            let cell: UICollectionViewCell = context.dequeueReusableCell(at: index,
                                                                         for: self,
                                                                         nibName: type.className) else {
                                                                            return UICollectionViewCell()
        }
        (cell as? ViewModelConfigurable)?.configure(with: item)
        return cell
    }
    
    private func getDummyViewForModel(with context: ListCollectionContext,
                                      at index: Int) -> UICollectionViewCell {
        var opType: ViewModelConfigurable.Type?
        let item = dataSource[index]
        if let item = item {
            opType = item.viewClass()
        } else if let dummyViewClass = self.dummyViewClass {
            opType = dummyViewClass
        }
        guard let type = opType else { return UICollectionViewCell() }
        var cell: UICollectionViewCell?
        if let reusableCell = reuseManager[type.className] as? UICollectionViewCell {
            cell = reusableCell
        } else {
            cell = context.dequeueReusableCell(at: .max,
                                               for: self,
                                               nibName: type.className)
            reuseManager[type.className] = cell
        }
        (cell as? ViewModelConfigurable)?.configure(with: item)
        return cell ?? UICollectionViewCell()
    }
    
    private func getConfiguredHeaderForModel(with context: ListCollectionContext,
                                             at index: Int) -> UICollectionReusableView {
        guard let headerSource = headerDataSource else { return UICollectionReusableView() }
        let type = headerSource.viewClass()
        let cell: UICollectionReusableView = context.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                                      for: self,
                                                                                      nibName: type.className,
                                                                                      bundle: .main,
                                                                                      at: index)
        (cell as? ViewModelConfigurable)?.configure(with: headerDataSource)
        return cell
    }
    
    private func getDummyHeaderForModel(with context: ListCollectionContext,
                                        at index: Int) -> UICollectionReusableView {
        guard let headerSource = headerDataSource else { return UICollectionReusableView() }
        let type = headerSource.viewClass()
        let cell: UICollectionReusableView = context.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                                      for: self,
                                                                                      nibName: type.className,
                                                                                      bundle: .main,
                                                                                      at: .max)
        (cell as? ViewModelConfigurable)?.configure(with: headerDataSource)
        return cell
    }
}
