/**
      This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
      Copyright © Adguard Software Limited. All rights reserved.

      Adguard for iOS is free software: you can redistribute it and/or modify
      it under the terms of the GNU General Public License as published by
      the Free Software Foundation, either version 3 of the License, or
      (at your option) any later version.

      Adguard for iOS is distributed in the hope that it will be useful,
      but WITHOUT ANY WARRANTY; without even the implied warranty of
      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
      GNU General Public License for more details.

      You should have received a copy of the GNU General Public License
      along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
*/

import UIKit

class RequestsBlockingController: UITableViewController {

    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var requestBlockingStateLabel: ThemableLabel!
    @IBOutlet weak var filtersLabel: ThemableLabel!
    @IBOutlet var themableLabels: [ThemableLabel]!
    
    private let theme: ThemeServiceProtocol = ServiceLocator.shared.getService()!
    private let resources: AESharedResourcesProtocol = ServiceLocator.shared.getService()!
    private let contentBlockerService: ContentBlockerService = ServiceLocator.shared.getService()!
    private let antibanner: AESAntibannerProtocol = ServiceLocator.shared.getService()!
    private let dnsFiltersService: DnsFiltersServiceProtocol = ServiceLocator.shared.getService()!
    private let vpnManager: APVPNManager = ServiceLocator.shared.getService()!
    
    private let dnsBlacklistSegue = "dnsBlacklistSegue"
    private let dnsWhitelistSegue = "dnsWhitelistSegue"
    
    private var notificationToken: NotificationToken?
    
    // MARK: - View controller life cycle
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let dnsFilterService: DnsFiltersServiceProtocol = ServiceLocator.shared.getService()!
        if segue.identifier == dnsBlacklistSegue {
            if let controller = segue.destination as? ListOfRulesController {
                let model: ListOfRulesModelProtocol = SystemBlacklistModel(resources: resources, dnsFiltersService: dnsFilterService, theme: theme, vpnManager: vpnManager)
                controller.model = model
            }
        } else if segue.identifier == dnsWhitelistSegue {
            if let controller = segue.destination as? ListOfRulesController {
                let model: ListOfRulesModelProtocol = SystemWhitelistModel(dnsFiltersService: dnsFilterService, resources: resources, theme: theme, vpnManager: vpnManager)
                controller.model = model
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateTheme()
        
        notificationToken = NotificationCenter.default.observe(name: NSNotification.Name( ConfigurationService.themeChangeNotification), object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.updateTheme()
        }
        
        let dnsRequestsBlockingEnabledObj = resources.sharedDefaults().object(forKey: AEDefaultsDNSRequestsBlocking)
        let dnsRequestsBlockingEnabled: Bool = dnsRequestsBlockingEnabledObj as? Bool ?? true
        
        enabledSwitch.isOn = dnsRequestsBlockingEnabled
        requestBlockingStateLabel.text = enabledSwitch.isOn ? ACLocalizedString("on_state", nil) : ACLocalizedString("off_state", nil)
        
        setupBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let filtersDescriptionText = String(format: ACLocalizedString("filters_description_format", nil), dnsFiltersService.enabledFiltersCount, dnsFiltersService.allFiltersCount)
        filtersLabel.text = filtersDescriptionText
    }
    
    // MARK: - Table view delegate methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        theme.setupTableCell(cell)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 ? 0.0 : 0.1
    }

    @IBAction func enabledSwitchAction(_ sender: UISwitch) {
        resources.sharedDefaults().set(sender.isOn, forKey: AEDefaultsDNSRequestsBlocking)
        requestBlockingStateLabel.text = sender.isOn ? ACLocalizedString("on_state", nil) : ACLocalizedString("off_state", nil)
        
        vpnManager.restartTunnel()
    }
    
    private func updateTheme() {
        view.backgroundColor = theme.backgroundColor
        theme.setupLabels(themableLabels)
        theme.setupTable(tableView)
        theme.setupSwitch(enabledSwitch)
        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else { return }
            sSelf.tableView.reloadData()
        }
    }
    
}
