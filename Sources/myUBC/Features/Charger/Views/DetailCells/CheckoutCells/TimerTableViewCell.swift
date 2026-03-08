//
//  TimerTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-03-11.
//

import Lottie
import UIKit

class TimerTableViewCell: UITableViewCell {
    @IBOutlet var bellContentView: AnimationView!
    @IBOutlet private var timeLabelView: UIView?
    weak var timerProtocol: CheckoutProtocol?
    weak var reminderProtocol: RemindersTableViewControllerProtocol?

    @IBOutlet var baseView: UIView!
    @IBOutlet var stopBtn: UIButton!
    private var embeddedCountdownLabel: CountdownLabel?

    private var timeLabel: CountdownLabel? {
        guard let timeLabelView else {
            return nil
        }
        if let direct = timeLabelView as? CountdownLabel {
            return direct
        }
        if let embeddedCountdownLabel {
            return embeddedCountdownLabel
        }
        // Fallback: if nib resolves this outlet as UIView, create CountdownLabel in place.
        let fallback = CountdownLabel(frame: timeLabelView.bounds)
        fallback.translatesAutoresizingMaskIntoConstraints = false
        fallback.backgroundColor = .clear
        timeLabelView.addSubview(fallback)
        NSLayoutConstraint.activate([
            fallback.leadingAnchor.constraint(equalTo: timeLabelView.leadingAnchor),
            fallback.trailingAnchor.constraint(equalTo: timeLabelView.trailingAnchor),
            fallback.topAnchor.constraint(equalTo: timeLabelView.topAnchor),
            fallback.bottomAnchor.constraint(equalTo: timeLabelView.bottomAnchor)
        ])
        embeddedCountdownLabel = fallback
        return fallback
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        interfaceSetup()
        getTime()
    }

    private func interfaceSetup() {
        // Initialization code
        baseView.layer.cornerRadius = 8
        stopBtn.layer.cornerRadius = 8
        // Bell
        bellContentView.loopMode = .playOnce
        // Counter
        guard let timeLabel else { return }
        timeLabel.countdownDelegate = self
        timeLabel.animationType = .Evaporate
        timeLabel.font = UIFont(name: "AppleSDGothicNeo-Bold", size: 43)
        timeLabel.textColor = .label
        timeLabel.textAlignment = .center
    }

    private func getTime() {
        guard ReminderStateStore.hasPendingChargerTimer() else {
            return
        }

        if let targetDate = ReminderStateStore.chargerTimerTargetDate() {
            let timeInterval = targetDate.timeIntervalSinceNow
            if timeInterval < 0 {
                ReminderStateStore.clearChargerTimer()
                timerProtocol?.updateTable()
            }
            timeLabel?.addTime(time: timeInterval)
            timeLabel?.start()
            bellContentView.play()
        }
    }
}

extension TimerTableViewCell: CountdownLabelDelegate {
    func countdownFinished() {
        ReminderStateStore.clearChargerTimer()
        timerProtocol?.updateTable()
        reminderProtocol?.countdownFinished()
    }
}
