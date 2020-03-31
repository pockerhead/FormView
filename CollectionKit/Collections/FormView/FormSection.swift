//
//  AnyHeaderProvider.swift
//  SmartStaff
//
//  Created by artem on 27.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//

import UIKit

// swiftlint:disable all
class FormSection {
    var data: [ViewModelWithViewClass?] {
        didSet {
            (provider as? FormViewProvider)?.dataSource.data = data
        }
    }
    var headerData: ViewModelWithViewClass?
    var provider: (ItemProvider & CollectionReloadable)
    var tapHandler: FormViewHeaderProvider.TapHandler?
    var haveDidReloadSectionsClosure: Bool
    
    init(data: [ViewModelWithViewClass?],
         header: ViewModelWithViewClass? = nil,
         dummyViewClass: ViewModelConfigurable.Type? = nil,
         id: String = UUID().uuidString,
         tapHandler: FormViewProvider.TapHandler? = nil,
         headerTapHandler: FormViewHeaderProvider.TapHandler? = nil,
         didReorderItemsClosure: ((Int, Int) -> Void)? = nil,
         insets: UIEdgeInsets = .zero,
         spacing: CGFloat = 0,
         scrollDirection: UICollectionView.ScrollDirection = .vertical) {
        self.haveDidReloadSectionsClosure = didReorderItemsClosure != nil
        self.data = data
        self.headerData = header
        self.tapHandler = headerTapHandler
        let dataSource = FormViewDataSource(data: data)
        var layout: Layout
        if scrollDirection == .vertical {
            layout = FlowLayout(spacing: spacing)
        } else {
            layout = RowLayout(spacing: spacing)
        }
        layout = layout.inset(by: insets)
        provider = FormViewProvider(identifier: id,
                               dataSource: dataSource,
                               viewSource: FormViewViewSource(dummyViewNilClass: dummyViewClass),
                               didReorderItemsClosure: didReorderItemsClosure,
                               layout: layout,
                               tapHandler: tapHandler)
    }
}

class Spacer: FormSection {
    
    init(id: String) {
        super.init(data: [], id: "SpaceSection_\(id)")
        provider = SpaceProvider()
    }
}

class FooterSection: FormSection {
    let buttonCell = ButtonCell()
    
    init(viewModel: ButtonCell.ViewModel) {
        super.init(data: [], id: "FooterSection")
        self.buttonCell.configure(with: viewModel)
    }
}

class EmptySection: FormSection {
    let emptyView = EmptyView()
    var height: CGFloat = 0 {
        didSet {
            (provider as? SimpleViewProvider)?
                .sizeSource = SimpleViewSizeSource(
                    sizeStrategy: (
                        width: .fill,
                        height: .offset(height)
                    )
            )
        }
    }
    
    init(viewModel: EmptyView.ViewModel, id: String) {
        super.init(data: [], id: "EmptySection_\(id)")
        emptyView.configure(with: viewModel)
        provider = SimpleViewProvider(identifier: "EmptySection_\(id)",
                                      views: [emptyView],
                                      sizeStrategy: (width: .fill, height: .fill),
                                      layout: FlowLayout(),
                                      animator: AnimatedReloadAnimator())
    }
}
