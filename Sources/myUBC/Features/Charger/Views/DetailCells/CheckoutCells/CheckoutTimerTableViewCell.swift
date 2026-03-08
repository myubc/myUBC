//
//  CheckoutTimerTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-02-13.
//

import UIKit

class CheckoutTimerTableViewCell: UITableViewCell {
    // functions
    @IBOutlet var switchBtn: UISwitch!
    @IBOutlet var timerPicker: UIDatePicker!
    @IBOutlet var startBtn: UIButton!
    @IBOutlet var startBtnHolder: UIView!
    // UI
    @IBOutlet var switchBackgroundView: UIView!
    @IBOutlet var pickerBackgroundView: UIView!
    @IBOutlet var infoBackgroundView: UIView!
    // Legal
    @IBOutlet var legalPushBtn: UIButton!
    @IBOutlet var legalTermsBtn: UIButton!
    @IBOutlet var legalLoan: UIButton!

    var timerProtocol: CheckoutProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        setupUI()
        // Initialization code
    }

    func setupUI() {
        switchBackgroundView.layer.cornerRadius = 8
        pickerBackgroundView.layer.cornerRadius = 8
        infoBackgroundView.layer.cornerRadius = 8
        startBtnHolder.layer.cornerRadius = 8
        startBtn.setTitleColor(.white, for: .normal)
        startBtn.setTitleColor(.lightGray, for: .disabled)
        timerPicker.isEnabled = switchBtn.isOn
        timerPicker.countDownDuration = 14400 // 14400 seconds = 4 hours
        timerPicker.minuteInterval = 5
    }

    @IBAction func didSwitchBtn(_ sender: Any) {
        guard let delegate = timerProtocol else {
            switchBtn.isOn = false
            return
        }

        delegate.accessCheck(completion: {
            DispatchQueue.main.async {
                guard delegate.isGrantedNotificationAccess else {
                    self.switchBtn.isOn = false
                    delegate.showAlert()
                    return
                }

                self.timerPicker.isEnabled = self.switchBtn.isOn
                self.startBtn.isEnabled = self.switchBtn.isOn
                self.timerPicker.alpha = (self.switchBtn.isOn) ? 1 : 0.8
                self.startBtnHolder.backgroundColor = (self.switchBtn.isOn) ? #colorLiteral(red: 0, green: 0.3568627451, blue: 0.7450980392, alpha: 1) : .quaternaryLabel
            }
        })
    }

    @IBAction func didStartTimer(_ sender: Any) {
        let interval = timerPicker.countDownDuration
        timerProtocol?.startTimer(timeInterval: interval)
    }
}
