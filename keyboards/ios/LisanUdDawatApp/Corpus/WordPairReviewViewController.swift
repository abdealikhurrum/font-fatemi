import UIKit

// Shows the user every word pair sitting in the staging queue.
// They can approve or discard individual pairs, bulk-approve, bulk-discard,
// or upload approved pairs to the corpus.
// Nothing leaves the device until "Upload approved pairs" is tapped.

final class WordPairReviewViewController: UIViewController {

    private let manager = CorpusManager.shared
    private var pairs: [CorpusManager.StagedPair] = []
    private var uploadTask: Task<Void, Never>?

    // MARK: - Views

    private lazy var tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .insetGrouped)
        t.register(PairCell.self, forCellReuseIdentifier: PairCell.reuseID)
        t.dataSource = self
        t.delegate   = self
        return t
    }()

    private lazy var toolbar: UIToolbar = {
        let tb = UIToolbar()
        tb.translatesAutoresizingMaskIntoConstraints = false
        return tb
    }()

    private lazy var uploadButton: UIBarButtonItem = {
        UIBarButtonItem(
            title: "Upload approved",
            style: .done,
            target: self,
            action: #selector(uploadTapped)
        )
    }()

    private lazy var statusLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Word Pairs"
        view.backgroundColor = .systemGroupedBackground
        buildUI()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Approve all",
            style: .plain,
            target: self,
            action: #selector(approveAllTapped)
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    // MARK: - Setup

    private func buildUI() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addSubview(toolbar)

        let statusItem  = UIBarButtonItem(customView: statusLabel)
        let flexL       = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let discardItem = UIBarButtonItem(
            title: "Discard all",
            style: .plain,
            target: self,
            action: #selector(discardAllTapped)
        )
        discardItem.tintColor = .systemRed
        toolbar.setItems([discardItem, flexL, statusItem, flexL, uploadButton], animated: false)

        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
        ])
    }

    // MARK: - Data

    private func reload() {
        // Show unreviewed first, then approved, so the queue is clear at a glance
        let pending  = manager.pendingReview()
        let approved = manager.staged().filter { $0.approved == true }
        pairs = pending + approved
        tableView.reloadData()
        updateStatus()
    }

    private func updateStatus() {
        let pending  = manager.pendingReview().count
        let approved = manager.approvedPending().count
        statusLabel.text = "\(pending) unreviewed · \(approved) approved"
        uploadButton.isEnabled = approved > 0
    }

    // MARK: - Actions

    @objc private func approveAllTapped() {
        manager.approveAll()
        reload()
    }

    @objc private func discardAllTapped() {
        let alert = UIAlertController(
            title: "Discard all pending pairs?",
            message: "This removes all unreviewed pairs from your device. Pairs you already approved are not affected.",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Discard all pending", style: .destructive) { [weak self] _ in
            self?.manager.discardAll()
            self?.reload()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func uploadTapped() {
        uploadButton.isEnabled = false
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        toolbar.items?[2] = UIBarButtonItem(customView: spinner)

        uploadTask = Task {
            do {
                try await manager.uploadApproved()
                await MainActor.run {
                    self.showBanner("Uploaded successfully", success: true)
                    self.reload()
                }
            } catch {
                await MainActor.run {
                    self.showBanner("Upload failed: \(error.localizedDescription)", success: false)
                }
            }
            await MainActor.run {
                self.toolbar.items?[2] = UIBarButtonItem(customView: self.statusLabel)
                self.updateStatus()
            }
        }
    }

    private func showBanner(_ message: String, success: Bool) {
        let banner = UILabel()
        banner.text = message
        banner.textColor = .white
        banner.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        banner.backgroundColor = success ? .systemGreen : .systemRed
        banner.textAlignment = .center
        banner.alpha = 0
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            banner.heightAnchor.constraint(equalToConstant: 44),
        ])
        UIView.animate(withDuration: 0.3, animations: { banner.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.5, animations: { banner.alpha = 0 }) { _ in
                banner.removeFromSuperview()
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension WordPairReviewViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pairs.isEmpty ? 1 : pairs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if pairs.isEmpty {
            let cell = UITableViewCell()
            cell.textLabel?.text = "No word pairs collected yet."
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.textAlignment = .center
            return cell
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: PairCell.reuseID, for: indexPath
        ) as! PairCell
        cell.configure(with: pairs[indexPath.row])
        cell.onApprove = { [weak self] in
            self?.manager.approve(id: self!.pairs[indexPath.row].id)
            self?.reload()
        }
        cell.onDiscard = { [weak self] in
            self?.manager.discard(id: self!.pairs[indexPath.row].id)
            self?.reload()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        pairs.isEmpty ? nil : "Review each pair before sharing"
    }
}

extension WordPairReviewViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        pairs.isEmpty ? 60 : UITableView.automaticDimension
    }
}

// MARK: - PairCell

private final class PairCell: UITableViewCell {

    static let reuseID = "PairCell"

    var onApprove: (() -> Void)?
    var onDiscard: (() -> Void)?

    private let lsdLabel   = UILabel()
    private let romanLabel = UILabel()
    private let approveBtn = UIButton(type: .system)
    private let discardBtn = UIButton(type: .system)
    private let statusDot  = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        buildUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildUI() {
        lsdLabel.font = UIFont.systemFont(ofSize: 18)
        lsdLabel.textAlignment = .right
        lsdLabel.semanticContentAttribute = .forceRightToLeft

        romanLabel.font = UIFont.systemFont(ofSize: 15)
        romanLabel.textColor = .secondaryLabel

        statusDot.layer.cornerRadius = 5
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        statusDot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        statusDot.heightAnchor.constraint(equalToConstant: 10).isActive = true

        approveBtn.setTitle("✓", for: .normal)
        approveBtn.tintColor = .systemGreen
        approveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        approveBtn.addTarget(self, action: #selector(approveTapped), for: .touchUpInside)

        discardBtn.setTitle("✕", for: .normal)
        discardBtn.tintColor = .systemRed
        discardBtn.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        discardBtn.addTarget(self, action: #selector(discardTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [lsdLabel, romanLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let btnStack = UIStackView(arrangedSubviews: [approveBtn, discardBtn])
        btnStack.axis = .horizontal
        btnStack.spacing = 8

        let row = UIStackView(arrangedSubviews: [statusDot, textStack, btnStack])
        row.axis = .horizontal
        row.spacing = 10
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    func configure(with pair: CorpusManager.StagedPair) {
        lsdLabel.text   = pair.lsd
        romanLabel.text = pair.roman

        switch pair.approved {
        case .none:
            statusDot.backgroundColor = .systemOrange
            approveBtn.isHidden = false
            discardBtn.isHidden = false
        case .some(true):
            statusDot.backgroundColor = .systemGreen
            approveBtn.isHidden = true
            discardBtn.isHidden = true
        case .some(false):
            statusDot.backgroundColor = .systemRed
            approveBtn.isHidden = true
            discardBtn.isHidden = true
        }
    }

    @objc private func approveTapped() { onApprove?() }
    @objc private func discardTapped() { onDiscard?() }
}
