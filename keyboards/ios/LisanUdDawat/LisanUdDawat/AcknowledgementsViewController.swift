import UIKit

// MARK: - AcknowledgementsViewController
//
// Lists the licenses of the components bundled in this app: the FatemiMaqala
// typeface (MIT) and any third-party code. There are currently no third-party
// libraries — the app uses only Apple frameworks — but FatemiMaqala's MIT
// license requires its copyright notice to be reproduced wherever the font is
// distributed, which this screen satisfies.

final class AcknowledgementsViewController: UIViewController {

    private struct Credit {
        let name: String
        let summary: String
        let license: String
    }

    private let credits: [Credit] = [
        Credit(
            name: "FatemiMaqala",
            summary: "The Lisan ud Dawat typeface bundled with this app and used "
                + "to render Arabic/Urdu text. A Unicode-compliant fork of the "
                + "AlFatemi font project.",
            license: Acknowledgements.mitLicense(holder: "Abdeali Khurrum")
        ),
        Credit(
            name: "LigaCheh Keyboard",
            summary: "This app and its keyboard extension.",
            license: Acknowledgements.mitLicense(holder: "Abdeali Khurrum")
        ),
    ]

    private lazy var scrollView = UIScrollView()
    private lazy var stackView  = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Acknowledgements"
        view.backgroundColor = .systemGroupedBackground
        buildUI()
    }

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        stackView.addArrangedSubview(bodyLabel(
            "This app is distributed under the MIT License and includes the "
            + "following components."
        ))
        for credit in credits {
            stackView.addArrangedSubview(card(for: credit))
        }
    }

    private func card(for credit: Credit) -> UIView {
        let v = cardContainer(title: credit.name)
        v.addArrangedSubview(bodyLabel(credit.summary))

        let license = UILabel()
        license.text = credit.license
        license.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        license.textColor = .secondaryLabel
        license.numberOfLines = 0
        v.addArrangedSubview(license)
        return v
    }

    // MARK: - Helpers (match Setup tab styling)

    private func cardContainer(title: String) -> UIStackView {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 12
        v.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        v.isLayoutMarginsRelativeArrangement = true
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 12
        let t = UILabel()
        t.text = title
        t.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        v.addArrangedSubview(t)
        return v
    }

    private func bodyLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }
}

// MARK: - Shared license text

enum Acknowledgements {
    static func mitLicense(holder: String) -> String {
        """
        MIT License

        Copyright (c) 2026 \(holder)

        Permission is hereby granted, free of charge, to any person obtaining a \
        copy of this software and associated documentation files (the \
        "Software"), to deal in the Software without restriction, including \
        without limitation the rights to use, copy, modify, merge, publish, \
        distribute, sublicense, and/or sell copies of the Software, and to \
        permit persons to whom the Software is furnished to do so, subject to \
        the following conditions:

        The above copyright notice and this permission notice shall be included \
        in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS \
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF \
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. \
        IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY \
        CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, \
        TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE \
        SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        """
    }
}
