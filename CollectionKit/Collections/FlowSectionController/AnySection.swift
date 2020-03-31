//
//  AnySection.swift
//  SmartStaff
//
//  Created by artem on 28.02.2020.
//  Copyright © 2020 DIT. All rights reserved.
//

import Foundation
import IGListKit

class AnySection: ListDiffable {
    var commonId: String = ""
    var trueId: String
    var id: String {
        commonId + trueId
    }
    var sectionController: FlowSectionController
    
    init(_ data: [ViewModelWithViewClass?],
         dummyViewClass: ViewModelConfigurable.Type? = NotificationCell.self,
         header: ViewModelWithViewClass? = nil,
         headerHeight: CGFloat? = nil,
         inset: UIEdgeInsets = .zero,
         spacing: CGFloat = 8,
         tapAction: ((FlowSectionController?, Int) -> Void)? = nil,
         scrollDirection: UICollectionView.ScrollDirection = .vertical,
         id: String = UUID().uuidString) {
        self.trueId = id
        self.sectionController = FlowSectionController(dataSource: data,
                                                       headerDataSource: header,
                                                       headerHeight: headerHeight,
                                                       dummyViewClass: dummyViewClass,
                                                       inset: inset,
                                                       spacing: spacing,
                                                       tapAction: tapAction,
                                                       scrollDirection: scrollDirection)
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        id as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object else { return false }
        return self.diffIdentifier().isEqual(object.diffIdentifier())
    }
    
}
