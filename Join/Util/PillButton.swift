//
//  PillButton.swift
//  Join
//
//  Created by Riley Lai on 2022/11/22.
//

import UIKit

class PillButton: UIButton {
    override func updateConfiguration() {
        guard let configuration = configuration else {
            return
        }

        var updateConfiguration = configuration
        var background = UIButton.Configuration.filled().background

        let assignedBackgroundColor = updateConfiguration.baseBackgroundColor
        let assignedTitleColor = updateConfiguration.baseForegroundColor
        let enabledBackgroundColor = UIColor.Blue1?.withAlphaComponent(0.2) ?? .white
        let enabledTitleColor = UIColor.Blue1?.withAlphaComponent(0.7) ?? .black
        let disabledBackgroundColor = UIColor.Gray3?.withAlphaComponent(0.2) ?? .lightGray
        let disabledTitleColor = UIColor.Gray1?.withAlphaComponent(0.7) ?? .gray

        let backgroundColor: UIColor
        let titleColor: UIColor

        switch self.state {
        case .disabled:
            backgroundColor = assignedBackgroundColor ?? disabledBackgroundColor
            titleColor = assignedTitleColor ?? disabledTitleColor
        default:
            backgroundColor = assignedBackgroundColor ?? enabledBackgroundColor
            titleColor = assignedTitleColor ?? enabledTitleColor
        }

        updateConfiguration.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var outcome = incoming
                outcome.foregroundColor = titleColor
                outcome.font = UIFont.systemFont(ofSize: 14)
                return outcome
            }

        updateConfiguration.cornerStyle = .capsule
        updateConfiguration.buttonSize = .mini
        background.backgroundColor = backgroundColor
        updateConfiguration.background = background

        self.configuration = updateConfiguration
    }
}
