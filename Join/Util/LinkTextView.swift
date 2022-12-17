//
//  InteractiveLinkLabel.swift
//  Join
//
//  Created by Riley Lai on 2022/11/29.
//

import UIKit

class LinkTextView: UITextView, UITextViewDelegate {
    typealias Links = [String: String]
    typealias OnLinkTap = (URL) -> Bool

    var onLinkTap: OnLinkTap?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        isEditable = false
        isSelectable = true
        isScrollEnabled = false
        delegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func addLinks(_ links: Links) {
        guard attributedText.length > 0 else { return }
        let myText = NSMutableAttributedString(attributedString: attributedText)
        let font: UIFont = .systemFont(ofSize: 12, weight: .bold)
        for (linkText, urlString) in links where !linkText.isEmpty {
                let linkRange = myText.mutableString.range(of: linkText)
                myText.addAttribute(.link, value: urlString, range: linkRange)
                myText.addAttributes(
                    [.font: font,
                     .underlineStyle: NSUnderlineStyle.single.rawValue],
                    range: linkRange)
        }
        attributedText = myText
    }

    func textView(
        _ textView: UITextView, shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction) -> Bool {
        onLinkTap?(URL) ?? true
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        textView.selectedTextRange = nil
    }
}
