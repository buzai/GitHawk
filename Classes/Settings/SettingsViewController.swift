//
//  SettingsViewController2.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/31/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SafariServices

final class SettingsViewController: UITableViewController {

    var sessionManager: GithubSessionManager!
    var client: GithubClient!
    weak var rootNavigationManager: RootNavigationManager? = nil

    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var reviewAccessCell: StyledTableCell!
    @IBOutlet weak var reportBugCell: StyledTableCell!
    @IBOutlet weak var viewSourceCell: StyledTableCell!
    @IBOutlet weak var signOutCell: StyledTableCell!
    @IBOutlet weak var backgroundFetchSwitch: UISwitch!
    @IBOutlet weak var openSettingsButton: UIButton!
    @IBOutlet weak var badgeCell: UITableViewCell!
    @IBOutlet weak var markReadSwitch: UISwitch!
    @IBOutlet weak var accountsCell: StyledTableCell!

    override func viewDidLoad() {
        super.viewDidLoad()

        versionLabel.text = Bundle.main.prettyVersionString
        markReadSwitch.isOn = NotificationClient.readOnOpen()

        updateBadge()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(SettingsViewController.updateBadge),
            name: NSNotification.Name.UIApplicationDidBecomeActive,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rz_smoothlyDeselectRows(tableView: tableView)

        accountsCell.detailTextLabel?.text = sessionManager.focusedUserSession?.username ?? Strings.unknown
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? SettingsAccountsViewController {
            controller.client = client
            controller.sessionManager = sessionManager
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)

        if cell === reviewAccessCell {
            onReviewAccess()
        } else if cell === reportBugCell {
            onReportBug()
        } else if cell === viewSourceCell {
            onViewSource()
        } else if cell === signOutCell {
            tableView.deselectRow(at: indexPath, animated: true)
            onSignOut()
        }
    }

    // MARK: Private API

    @IBAction func onDone(_ sender: Any) {
        dismiss(animated: true)
    }

    func onReviewAccess() {
        guard let url = URL(string: "https://github.com/settings/connections/applications/\(GithubAPI.clientID)")
            else { fatalError("Should always create GitHub issue URL") }
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }

    func onReportBug() {
        let template = "\(Bundle.main.prettyVersionString)\nDevice: \(UIDevice.current.modelName) (iOS \(UIDevice.current.systemVersion)) \n"
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""

        guard let url = URL(string: "https://github.com/rnystrom/GitHawk/issues/new?body=\(template)")
            else { fatalError("Should always create GitHub issue URL") }
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }

    func onViewSource() {
        guard let url = URL(string: "https://github.com/rnystrom/GitHawk/")
            else { fatalError("Should always create GitHub URL") }
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }

    func onSignOut() {
        let cancelAction = UIAlertAction(title: Strings.cancel, style: .cancel, handler: nil)

        let signoutAction = UIAlertAction(title: Strings.signout, style: .destructive) { _ in
            self.signout()
        }

        let title = NSLocalizedString("Are you sure?", comment: "")
        let message = NSLocalizedString("All accounts will be signed out. Do you want to continue?", comment: "")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(cancelAction)
        alert.addAction(signoutAction)

        present(alert, animated: true)
    }

    func signout() {
        sessionManager.logout()
    }

    func updateBadge() {
        BadgeNotifications.check { state in
            let authorized: Bool
            let enabled: Bool
            switch state {
            case .initial:
                // throwing switch will prompt
                authorized = true
                enabled = false
            case .denied:
                authorized = false
                enabled = false
            case .disabled:
                authorized = true
                enabled = false
            case .enabled:
                authorized = true
                enabled = true
            }
            self.badgeCell.accessoryType = authorized ? .none : .disclosureIndicator
            self.openSettingsButton.isHidden = authorized
            self.backgroundFetchSwitch.isHidden = !authorized
            self.backgroundFetchSwitch.isOn = enabled
        }
    }

    @IBAction func onBackgroundFetchChanged() {
        BadgeNotifications.isEnabled = backgroundFetchSwitch.isOn
        BadgeNotifications.configure() { granted in
            self.updateBadge()
        }
    }

    @IBAction func onSettings(_ sender: Any) {
        guard let url = URL(string: UIApplicationOpenSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    @IBAction func onMarkRead(_ sender: Any) {
        NotificationClient.setReadOnOpen(open: markReadSwitch.isOn)
    }
}
