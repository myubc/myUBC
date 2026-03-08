//
//  WhatsNewTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2021-02-22.
//

import AVKit
import UIKit

class WhatsNewTableViewCell: UITableViewCell {
    static var nib: String {
        return "WhatsNewTableViewCell"
    }

    @IBOutlet var gifView: UIImageView!
    @IBOutlet var continueBtn: UIButton!

    func setupUI() {
        continueBtn.layer.cornerRadius = 8
        // gifView.layer.cornerRadius = 8
        // gifView.layer.masksToBounds = true
        // playVideo(from: "preview.mov")
        /* if let url = Bundle.main.url(forResource: "demo", withExtension: "gif"),
            let imageData = try? Data(contentsOf: url) {
             gifView.image = UIImage.gifImageWithData(imageData)
         } */
    }

    private func playVideo(from file: String) {
        let file = file.components(separatedBy: ".")

        guard let path = Bundle.main.path(forResource: file[0], ofType: file[1]) else {
            debugPrint("\(file.joined(separator: ".")) not found")
            return
        }
        let player = AVPlayer(url: URL(fileURLWithPath: path))

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = gifView.bounds
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        gifView.layer.addSublayer(playerLayer)
        player.play()
        player.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(notification:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
}
