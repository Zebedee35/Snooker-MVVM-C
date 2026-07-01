//
//  MatchDetailBuilder.swift
//  Snooker
//

import UIKit

enum MatchDetailBuilder {
    static func make(presentation: MatchDetailPresentation) -> MatchDetailViewController {
        MatchDetailViewController(presentation: presentation)
    }
}
