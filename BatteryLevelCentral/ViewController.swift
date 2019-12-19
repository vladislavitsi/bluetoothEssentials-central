//
//  ViewController.swift
//  BatteryLevelCentral
//
//  Created by Vladislav Kleschenko on 12/15/19.
//  Copyright © 2019 Vladislav Kleschenko. All rights reserved.
//

import UIKit
import CoreBluetooth

final class ViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let bluetoothService = BluetoothService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        bluetoothService.didUpdateValue = { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bluetoothService.peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? BatteryStatusTableViewCell else { fatalError() }
        let peripheralData = bluetoothService.peripherals[indexPath.row]
        cell.configure(withName: peripheralData.name, batteryLevel: peripheralData.batteryLevel)
        return cell
    }
}
