//
//  HeadToHeadBuilder.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

enum HeadToHeadBuilder {
    static func build(headerPresentation: HeadToHeadHeaderPresentation) -> HeadToHeadViewController {
        let viewModel = HeadToHeadViewModel(headerPresentation: headerPresentation)
        let viewController = HeadToHeadViewController(viewModel: viewModel)
        return viewController
    }
}
