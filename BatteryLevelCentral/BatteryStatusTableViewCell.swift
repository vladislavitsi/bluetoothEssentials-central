//
//  BatteryStatusTableViewCell.swift
//  BatteryLevelCentral
//
//  Created by Vladislav Kleschenko on 12/15/19.
//  Copyright © 2019 Vladislav Kleschenko. All rights reserved.
//

import UIKit

final class BatteryStatusTableViewCell: UITableViewCell {

    @IBOutlet private weak var name: UILabel!
    @IBOutlet private weak var batteryLevel: UILabel!

    func configure(withName name: String, batteryLevel: Int) {
        self.name.text = name
        self.batteryLevel.text = "\(batteryLevel) %"
    }
}
