//
//  ViewController.swift
//  SwiftScreenRecordWithReplayKit
//
//  Created by Mehmet Fatih YILDIZ on 1/14/20.
//  Copyright © 2020 Mehmet Fatih YILDIZ. All rights reserved.
//

import UIKit
import ReplayKit
import AVKit
import Photos

class HomeViewController: UIViewController, RPPreviewViewControllerDelegate {
	
	var ts: String!
	var documentsPath: NSString!
	var videoOutputURL: URL!
	var videoWriter: AVAssetWriter!
	var videoWriterInput: AVAssetWriterInput!
	var btn: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationController?.isNavigationBarHidden = false
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(startRecording))

		// Build screen layout
		self.view.backgroundColor = .white
		btn = UIButton(type:.system)
		btn.backgroundColor = .blue
		btn.setTitle("Button", for: .normal)
		btn.tintColor = .white
		btn.layer.cornerRadius = 5
		btn.frame = CGRect(x: 50, y: 150, width: 100, height: 40)
		UIView.animate(withDuration: 10.0, delay: 0, options: [.repeat, .autoreverse], animations: {
			self.btn.frame = CGRect(x: 50, y: 700, width: 100, height: 40)
		}, completion: nil)
		self.view.addSubview(btn)
	}
	
	@objc func startRecording() {
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Stop", style: .plain, target: self, action: #selector(self.stopRecording))

        // Create the file path to write to
		ts = String(Int(NSDate().timeIntervalSince1970 * 1000))
        documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
		videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("MyVideo" + ts + ".mp4"))

        // Check the file does not already exist by deleting it if it does
        do {
			try FileManager.default.removeItem(at: videoOutputURL)
        } catch {
			print("File can not be deleted or not found! ", error.localizedDescription)
		}

        do {
			try videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileType.mp4)
        } catch let writerError as NSError {
            print("Error opening video file", writerError)
            videoWriter = nil
            return
        }

        // Create the video settings
        let videoSettings: [String : Any] = [
            AVVideoCodecKey  : AVVideoCodecType.h264,
            AVVideoWidthKey  : UIScreen.main.bounds.size.width,
            AVVideoHeightKey : UIScreen.main.bounds.size.height
        ]

        // Create the asset writer input object whihc is actually used to write out the video
        // with the video settings we have created
		videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
		videoWriterInput.expectsMediaDataInRealTime = true
		videoWriter.add(self.videoWriterInput)

        // Tell the screen recorder to start capturing and to call the handler when it has a
        // sample
		RPScreenRecorder.shared().startCapture(handler: {(sample, bufferType, error) in

            guard error == nil else {
                //Handle error
                print("Error starting capture")
                return;
            }
			
			if CMSampleBufferDataIsReady(sample){
				DispatchQueue.main.async { [weak self] in
					if self?.videoWriter.status == AVAssetWriter.Status.unknown {
						self?.videoWriter.startWriting()
						self?.videoWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
					}

					if self?.videoWriter.status == AVAssetWriter.Status.failed {
						print("Error occured, status = \(String(describing: self?.videoWriter.status.rawValue)), \(self?.videoWriter.error!.localizedDescription) ### \(String(describing: self?.videoWriter.error))")
					   return
				   }
				   
				   if (bufferType == .video) {
						if self?.videoWriterInput.isReadyForMoreMediaData ?? true {
							self?.videoWriterInput.append(sample)
						}
				   }
				}
			}
        })
    }

    @objc func stopRecording() {
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(self.startRecording))
		//self.btn.layer.removeAllAnimations()
		
        // Stop Recording the screen
        RPScreenRecorder.shared().stopCapture( handler: { (error) in
            print("stopping recording")
        })

        self.videoWriterInput.markAsFinished();
        self.videoWriter.finishWriting {
            print("finished writing video")
			
			let gifOutputURL = URL(fileURLWithPath: self.documentsPath.appendingPathComponent("MyGif" + self.ts + ".gif"))
			
			// Additional filters:
			// resize the gif:
			//    scale=480:-1:flags=lanczos
			// high quality color palette:
			//    split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse
			
			let ffmpegCmd = "-i " + self.videoOutputURL.path + " -vf fps=20 -loop 0 " + gifOutputURL.path
			print("ffmpegCmd: \(ffmpegCmd)")
			MobileFFmpeg.execute(ffmpegCmd)

			print("finished writing gif file")
			print(gifOutputURL)
			
			// Clean up movie file:
			do {
				try FileManager.default.removeItem(at: self.videoOutputURL)
			} catch {
				print(error.localizedDescription)
			}
			
            // Now save the gif to photo album
            PHPhotoLibrary.shared().performChanges({
				//PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoOutputURL)
				PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: gifOutputURL)
            }) { saved, error in
                if saved {
                    let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
                if error != nil {
                    print("Video did not save for some reason", error.debugDescription)
                    debugPrint(error?.localizedDescription ?? "error is nil")
                }
            }
        }
	}

    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
    }

}

