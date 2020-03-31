//
//  FormView.swift
//  SmartStaff
//
//  Created by artem on 26.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//

// swiftlint:disable all
import IGListKit
import Foundation

final class FormView: CollectionView {
    var sections: [FormSection] = [] {
        didSet {
            let layout: Layout
            if scrollDirection == .vertical {
                layout = FlowLayout()
            } else {
                layout = RowLayout()
            }
            provider = FormViewHeaderProvider(identifier: "RootProvider",
                                         layout: layout,
                                         sections: self.sections)
                .bindReload({
                    DispatchQueue.main.async {
                        self.didReloadClosure?()
                    }
                })
        }
    }
    
    var emptyView = EmptyView()
    
    func displayEmptyView(model: EmptyView.ViewModel, height: CGFloat? = nil) {
        emptyView.configure(with: model)
        let heightStrategy: SimpleViewSizeSource.ViewSizeStrategy
        if let height = height {
            heightStrategy = .offset(height)
        } else {
            heightStrategy = .fill
        }
        let sizeStrategy = (width: SimpleViewSizeSource.ViewSizeStrategy.fill, height: heightStrategy)
        provider = SimpleViewProvider(identifier: "emptyViewProvider",
                                      views: [emptyView],
                                      sizeStrategy: sizeStrategy,
                                      layout: FlowLayout(),
                                      animator: AnimatedReloadAnimator())
    }
    
    var scrollDirection: UICollectionView.ScrollDirection = .vertical
    
    var didReloadClosure: (() -> Void)?
    
    @discardableResult
    func didReload(_ didReload: (() -> Void)?) -> FormView {
        self.didReloadClosure = didReload
        return self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        delaysContentTouches = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        delaysContentTouches = false
    }
    
}
