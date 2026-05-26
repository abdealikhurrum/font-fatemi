import UIKit

final class LearnViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Learn"
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(ModuleCell.self, forCellReuseIdentifier: ModuleCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    // MARK: - Data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        LessonCatalog.modules.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ModuleCell.reuseID, for: indexPath) as! ModuleCell
        cell.configure(with: LessonCatalog.modules[indexPath.row])
        return cell
    }

    // MARK: - Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let module = LessonCatalog.modules[indexPath.row]
        if module.isVerbTraining {
            navigationController?.pushViewController(VerbTrainingViewController(), animated: true)
        } else {
            navigationController?.pushViewController(LessonViewController(module: module), animated: true)
        }
    }
}

// MARK: - Module card cell

private final class ModuleCell: UITableViewCell {

    static let reuseID = "ModuleCell"

    private let iconView    = UIImageView()
    private let titleLabel  = UILabel()
    private let subtitleLabel = UILabel()
    private let badgeLabel  = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        buildLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildLayout() {
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 12
        iconView.layer.masksToBounds = true
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)

        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true

        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.layer.masksToBounds = true
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let row = UIStackView(arrangedSubviews: [iconView, textStack, badgeLabel])
        row.axis = .horizontal
        row.spacing = 14
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),
            badgeLabel.heightAnchor.constraint(equalToConstant: 24),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
        ])
    }

    func configure(with module: LessonModule) {
        iconView.image = UIImage(systemName: module.systemImage)
        iconView.tintColor = .white
        iconView.backgroundColor = module.accent

        titleLabel.text = module.title
        subtitleLabel.text = module.subtitle

        let count = module.isVerbTraining ? VerbPrompts.all.count : module.stepCount
        badgeLabel.text = module.isVerbTraining ? "\(count) prompts" : "\(count) steps"
        badgeLabel.textColor = module.accent
        badgeLabel.backgroundColor = module.accent.withAlphaComponent(0.15)
    }
}
