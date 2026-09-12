import AppKit
import Foundation

enum AboutPresenter {
    static let githubURL = URL(string: "https://github.com/Nealletu/oneStep-Action")!

    @MainActor
    static func show() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: makeCredits()
        ])
    }

    private static func makeCredits() -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 4

        let bodyFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let credits = NSMutableAttributedString()

        let blurb = String(localized: "about.blurb")
        credits.append(NSAttributedString(string: blurb, attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraph,
        ]))

        credits.append(NSAttributedString(string: "\n\n", attributes: [
            .font: bodyFont,
            .paragraphStyle: paragraph,
        ]))

        let linkTitle = String(localized: "about.github")
        let linkRange = NSRange(location: credits.length, length: (linkTitle as NSString).length)
        credits.append(NSAttributedString(string: linkTitle, attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.linkColor,
            .paragraphStyle: paragraph,
            .link: githubURL,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]))
        _ = linkRange

        let repoLine = NSAttributedString(string: "\n" + githubURL.absoluteString, attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize - 1),
            .foregroundColor: NSColor.tertiaryLabelColor,
            .paragraphStyle: paragraph,
        ])
        credits.append(repoLine)

        return credits
    }
}
