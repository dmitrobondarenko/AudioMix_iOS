//
//  ViewController.swift
//  MixAudio
//
//  Created by com on 9/7/19.
//  Copyright © 2019 KMHK. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var tableView: UITableView?
    var player: AVAudioPlayer?
    
    let titles = ["sample1", "sample2", "sample3", "sample4", "mixed 2 and 4 for 5 sec"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView = UITableView(frame: view.frame, style: .plain)
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.register(UITableViewCell.self, forCellReuseIdentifier: "tableCell")
        view.addSubview(tableView!)
    }

    // MARK: audio methods
    func playAudio(name: String) {
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            player = try? AVAudioPlayer(contentsOf: url)
            player!.play()
        }
    }
    
    func playAudio(url: URL) {
        player = try? AVAudioPlayer(contentsOf: url)
        player!.play()
    }
    
    func mixAudioFiles(names: [String]) {
        var assets = [AVURLAsset]()
        for name in names {
            if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
                let asset = AVURLAsset(url: url)
                assets.append(asset)
            }
        }
        
        mixAudio(audios: assets, duration: CMTime(seconds: 5, preferredTimescale: 100)) { (output) in
            self.playAudio(url: output)
        }
    }
    
    func mixAudio(audios: [AVAsset], duration: CMTime, completion:@escaping ((URL)->())) {
        let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("output.m4a")
        if FileManager.default.fileExists(atPath: output!.path) {
            try? FileManager.default.removeItem(at: output!)
        }
        
        let composition = AVMutableComposition()
        
        var from = CMTime.zero
        
        for asset in audios {
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID())
            
            var track = asset.tracks(withMediaType: .audio)
            let assetTrack = track[0]
            
            //let assetDuration = assetTrack.timeRange.duration
            
            let timeRange = CMTimeRange(start: from, duration: duration)
            
            try? compositionAudioTrack?.insertTimeRange(timeRange, of: assetTrack, at: CMTime.zero/*from*/)
            from = from + duration
        }
        
        // export audio
        let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        assetExport?.outputFileType = .m4a
        assetExport?.outputURL = output
        assetExport?.exportAsynchronously(completionHandler: {
            switch assetExport?.status {
            case .some(.failed):
                print("failed ", assetExport?.error?.localizedDescription as Any)
            case .some(.completed):
                print("finished successfully")
                completion(output!)
            default:
                print("...")
            }
        })
    }
}

// MARK:- table view methods
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "tableCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "tableCell")
        }
        
        cell?.textLabel?.text = "play " + titles[indexPath.row]
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0...3:
            playAudio(name: titles[indexPath.row])
            break
        default:
            mixAudioFiles(names: [titles[1], titles[3]]) // mix sample2.mp3 and sample4.mp3
            break
        }
    }
}
