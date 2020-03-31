//
//  FormVC.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//

import FloatingPanel
import UIKit

class FormVC: UIViewController, FloatingPanelExtendedDelegate {
    
    // MARK: Properties
    
    weak var floatingPanel: FloatingPanelController?
    let floatingLayout = AdaptiveFloatingLayout()
    var contentHeight: CGFloat = 120
    
    var scrollViewWrapper: ScrollViewWrapper? {
        rootView
    }
    
    var rootView: FormVCRootView! {
        (view as! FormVCRootView)
    }
    
    var storedSections: [FormSection] = [] {
        didSet {
            reloadSections()
        }
    }
    
    /// Point to override
    var sections: [FormSection] {
        []
    }
    
    var storedFooter: ButtonCell.ViewModel? = nil {
        didSet {
           reloadSections()
        }
    }
    
    /// Point to override
    var footer: ButtonCell.ViewModel? {
        storedFooter
    }
    
    // MARK: Initialization
    
    init(sections: [FormSection] = []) {
        storedSections = sections
        super.init(nibName: nil, bundle: nil)
        if !isViewLoaded {
            loadViewIfNeeded()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func loadView() {
        view = FormVCRootView()
        rootView.controller = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        reloadSections()
    }
    
    // MARK: View's input
    
    func reloadSections() {
        rootView.display(storedFooter ?? footer, animated: true)
        rootView.display(storedSections.isEmpty ? sections : storedSections)
    }
    
    func displayEmptyView(_ viewModel: EmptyView.ViewModel) {
        rootView.display(storedFooter ?? footer, animated: true)
        rootView.displayEmptyView(viewModel)
    }
    
    func viewDidReloadCollection(with height: CGFloat) {
        guard floatingPanel != nil else { return }
        contentHeight = height
        floatingLayout.halfInset = contentHeight
        UIView.animate(withDuration: .pi * 0.10) {[weak self] in
            guard let self = self else { return }
            self.floatingPanel?.updateLayout()
        }
    }
}

// MARK: FloatingPanelControllerDelegate

extension FormVC: FloatingPanelControllerDelegate {
    
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        floatingLayout
    }
}
