//
//  FormViewSource.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//
// swiftlint:disable all

import IGListKit
import Foundation

class CollectionViewDequeuer: NSObject, ListAdapterDataSource {
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private lazy var collectionAdapter = ListAdapter(updater: ListAdapterUpdater(), viewController: nil)
    private lazy var sectionController = FlowSectionController(dataSource: [])
    
    private override init(){
        super.init()
        collectionAdapter.collectionView = collectionView
        collectionAdapter.dataSource = self
        collectionAdapter.performUpdates(animated: true, completion: nil)
    }
    
    static let shared = CollectionViewDequeuer()
    
    
    
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        [AnySection([nil])]
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        sectionController
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        nil
    }
    
    func dequeueReusableCell(at index: Int, nibName: String) -> UICollectionViewCell? {
        return sectionController.collectionContext?.dequeueReusableCell(at: index,
                                                                        for: sectionController,
                                                                        nibName: nibName)
    }
}

open class FormViewViewSource {
    
    public private(set) lazy var reuseManager = CollectionReuseViewManager.shared
    var dummyViewSource: [String: UIView] = [:]
    var nilDataDummyViewClass: ViewModelConfigurable.Type?
    
    /// Should return a new view for the given data and index
    func view(data: ViewModelWithViewClass?, index: Int) -> ViewModelConfigurable {
        let dequeuedView = { self.getView(at: index, with: data) }()
        let view = reuseManager.dequeue(viewClass: NSStringFromClass(data?.viewClass() ?? nilDataDummyViewClass ?? NotificationCell.self), dequeuedView) as! ViewModelConfigurable
        update(view: view, data: data, index: index)
        return view
    }
    
    func getView(at index: Int, with data: ViewModelWithViewClass?) -> UIView {
        guard let data = data else {
            let view = CollectionViewDequeuer.shared.dequeueReusableCell(at: index, nibName: nilDataDummyViewClass?.className ?? NotificationCell.self.className)
            return view ?? UIView()
        }
        let opType = data.viewClass()
        var cell: UIView
        if let reusableCell = CollectionViewDequeuer.shared.dequeueReusableCell(at: index, nibName: opType.className) {
            cell = reusableCell
            if dummyViewSource[opType.className] == nil {
                dummyViewSource[opType.className] = CollectionViewDequeuer.shared.dequeueReusableCell(at: index, nibName: opType.className)
            }
        } else {
            let viewClass = data.viewClass()
            let viewClassString = viewClass.className
            let viewToDequeue = viewClass.init()
            if dummyViewSource[viewClassString] == nil {
                dummyViewSource[viewClassString] = viewClass.init()
            }
            cell = viewToDequeue
        }
        return cell
    }
    
    func getDummyView(data: ViewModelWithViewClass?) -> UIView {
        guard let data = data else {
            let view = CollectionViewDequeuer.shared.dequeueReusableCell(at: .max, nibName: nilDataDummyViewClass?.className ?? NotificationCell.self.className)
            return view ?? UIView()
        }
        let opType = data.viewClass()
        guard dummyViewSource[opType.className] == nil else {
            return dummyViewSource[opType.className]!
        }
        var cell: UIView
        if let reusableCell = CollectionViewDequeuer.shared.dequeueReusableCell(at: .max, nibName: opType.className) {
            cell = reusableCell
            if dummyViewSource[opType.className] == nil {
                dummyViewSource[opType.className] = reusableCell
            }
        } else {
            let viewClass = data.viewClass()
            let viewClassString = viewClass.className
            let viewToDequeue = viewClass.init()
            if dummyViewSource[viewClassString] == nil {
                dummyViewSource[viewClassString] = viewToDequeue
            }
            cell = viewToDequeue
        }
        return cell
    }
    
    /// Should update the given view with the provided data and index
    func update(view: ViewModelConfigurable, data: ViewModelWithViewClass?, index: Int) {
        view.configure(with: data)
    }
    
    init(dummyViewNilClass: ViewModelConfigurable.Type? = nil) {
        self.nilDataDummyViewClass = dummyViewNilClass
    }
}

extension FormViewViewSource: AnyViewSource {
    public final func anyView(data: Any, index: Int) -> UIView {
        return view(data: data as? ViewModelWithViewClass, index: index)
    }
    
    public final func anyUpdate(view: UIView, data: Any, index: Int) {
        return update(view: view as! ViewModelConfigurable, data: data as? ViewModelWithViewClass, index: index)
    }
}

extension UIView {
    func removeAllGestures() {
        gestureRecognizers?.forEach { gest in
            removeGestureRecognizer(gest)
        }
    }
}
