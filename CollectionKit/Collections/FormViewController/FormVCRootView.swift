//
//  FormVCRootView.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//

import UIKit

class FormVCRootView: UIView, ScrollViewWrapper {

    // MARK: Dependencies
    weak var controller: FormVC?
    
    // MARK: Properties
    
    let rootFormView = FormView()
    let footer = ButtonCell()
    private var _footerHeight: NSLayoutConstraint?
    
    var footerHeight: CGFloat {
        _footerHeight?.constant ?? 0
    }
    
    var scrollView: UIScrollView? {
        rootFormView
    }
    
    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureUI()
    }
    
    // MARK: UI Configuration
    
    private func configureUI() {
        themeProvider.register(observer: self)
        configureFormView()
        configureFooter()
    }
    
    func configureFormView() {
        addSubview(rootFormView)
        rootFormView.anchor(top: safeAreaLayoutGuide.topAnchor,
                            left: safeAreaLayoutGuide.leftAnchor,
                            right: safeAreaLayoutGuide.rightAnchor)
        rootFormView.didReload {[weak self] in
            guard let self = self else { return }
            self.controller?.viewDidReloadCollection(with: self.fullContentHeight())
        }
    }
    
    func configureFooter() {
        addSubview(footer)
        footer.anchor(top: rootFormView.bottomAnchor,
                      left: safeAreaLayoutGuide.leftAnchor,
                      bottom: safeAreaLayoutGuide.bottomAnchor,
                      right: safeAreaLayoutGuide.rightAnchor)
        _footerHeight = footer.anchorWithReturnAnchors(heightConstant: 44).first
    }
    
    // MARK: Controller's output
    
    func display(_ sections: [FormSection]) {
        if let emptySection = sections.first(where: { $0 is EmptySection }) as? EmptySection {
            emptySection.height = footerHeight
        }
        rootFormView.sections = sections
    }
    
    func display(_ footerViewModel: ButtonCell.ViewModel?, animated: Bool) {
        _footerHeight?.constant = footerViewModel == nil ? 0.5 :  footer.sizeWith(bounds.size, data: footerViewModel)?.height ?? 0
        footer.configure(with: footerViewModel)
        if animated {
            UIView.animate(withDuration: 0.3) {[weak self] in
                guard let self = self else { return }
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }
    
    func fullContentHeight() -> CGFloat {
        let height = ((controller?.navigationController?.navigationBar.isHidden ?? true)
        ? 0
        : controller?.navigationController?.navigationBar.frame.height ?? 0) +
            rootFormView.contentSize.height + footerHeight
        return min(height, fullEdgesHeight)
    }
    
    func displayEmptyView(_ viewModel: EmptyView.ViewModel) {
        rootFormView.displayEmptyView(model: viewModel, height: footerHeight)
        self.controller?.viewDidReloadCollection(with: self.fullEdgesHeight)
    }
}

// MARK: Themeable

extension FormVCRootView: Themeable {
    
    func apply(theme: Theme) {
        backgroundColor = theme.tableViewBackground
        rootFormView.backgroundColor = theme.tableViewBackground
    }
}
