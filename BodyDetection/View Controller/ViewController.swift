/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The sample app's main view controller.
 */

import UIKit
import RealityKit
import ARKit
import Combine
import ReplayKit
import Photos


let maxHandAngle = 60.0 // degrees

enum Plane {
    case XY
    case XZ
    case YZ
}

struct Position3D: Codable{
    var x: Float
    var y: Float
    var z: Float
}

struct SkeletonPositions: Codable{
    var rightHand: Position3D
    var leftHand: Position3D
    var rightFoot: Position3D
    var leftFoot: Position3D
    var rightShoulder: Position3D
    var leftShoulder: Position3D
    var hip: Position3D
    var head: Position3D
}

func mapJointToPosition3D(arSkeleton: ARSkeleton3D, jointName: ARSkeleton.JointName) -> Position3D {
        
    let index = ARSkeletonDefinition.defaultBody3D.index(for: jointName)
    let modelTransform = arSkeleton.jointModelTransforms[index]
    let position = Transform(matrix: modelTransform).translation
    
    let mappedValues = Position3D(x: position[0], y: position[1], z: position[2])
    
    return mappedValues
}

func mapARSkeletonToStruct(arSkeleton: ARSkeleton3D) -> SkeletonPositions {
    
    let skeletonPositions = SkeletonPositions(rightHand: mapJointToPosition3D(arSkeleton: arSkeleton, jointName: .rightHand), leftHand: mapJointToPosition3D(arSkeleton: arSkeleton, jointName: .leftHand), rightFoot: mapJointToPosition3D(arSkeleton: arSkeleton, jointName: .rightFoot), leftFoot: mapJointToPosition3D(arSkeleton: arSkeleton, jointName: .leftFoot), rightShoulder: mapJointToPosition3D(arSkeleton: arSkeleton, jointName: .rightShoulder),leftShoulder: mapJointToPosition3D(arSkeleton: arSkeleton, jointName: .leftShoulder) ,hip: mapJointToPosition3D(arSkeleton: arSkeleton, jointName: .root), head: mapJointToPosition3D(arSkeleton: arSkeleton, jointName: .head))
    
    return skeletonPositions
}

struct Frame: Codable {
    var skeleton: SkeletonPositions
    var timestamp: Int
    
    init(arSkeleton: ARSkeleton3D, timestamp: Int){
        self.skeleton =  mapARSkeletonToStruct(arSkeleton: arSkeleton)
        self.timestamp = timestamp
    }
}

func saveFrame(frames: [Frame]) {
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(frames)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        print(jsonString)
    } catch { print(error) }
}

//  Gets the angle betwen two points, relatie to a plane. For reference with respect to a phone being held up vertically recording someone, positive X is to the right, positive Y is up, and positive Z is coming at you.
//
// All angles are between -90 and 90 degrees, with the value of the 3rd dimension determining the sign of the angle.
// Example: If the relative plane is XY then positive Z means the angle is positive and negative Z means the angle is negative
func getAngleFromXYZ(endPoint: Position3D, origin: Position3D, relativePlane: Plane) -> Float{
        
    let xDiff = endPoint.x - origin.x
    let yDiff = endPoint.y - origin.y
    let zDiff = endPoint.z - origin.z
    
    // The tangent length is used to calculate the angle of the point
    // the tangent length is defined by a reference plane (specified below)
    var tangent = Float(0.0)
    var diff = Float(0.0)
    
    switch relativePlane{
    case .XY:
        tangent = ( pow(xDiff, 2) + pow(yDiff, 2)).squareRoot()
        diff = zDiff
    case .XZ:
        tangent = ( pow(xDiff, 2) + pow(zDiff, 2)).squareRoot()
        diff = yDiff
    case .YZ:
        tangent = ( pow(yDiff, 2) + pow(zDiff, 2)).squareRoot()
        diff = zDiff
    }

    let angle = atan2(diff, tangent)
    
    let degs = angle * 180 / Float.pi
    
    return Float(degs)
}


// This function uses the square of the distance of the arm angles from the neutral 'T' pose position
// to act as a score for the current jumping-jack Frame
func scoreJumpingJackMiddle(frame: Frame) -> Float {
        
    let skeleton = frame.skeleton
    let rightArmAngle = getAngleFromXYZ(endPoint: skeleton.rightHand, origin: skeleton.rightShoulder, relativePlane: Plane.XZ)
    let leftArmAngle = getAngleFromXYZ(endPoint: skeleton.leftHand, origin: skeleton.leftShoulder, relativePlane: Plane.XZ)
    
    
    // The max score for the neutral position is when the arm angles are as close to zero as possible
    let max_deviation = pow(Float(maxHandAngle), 2) + pow(Float(maxHandAngle), 2)
    let score =  (max_deviation - (pow(rightArmAngle, 2) + pow(leftArmAngle, 2)))
    
    return score
}

func scoreJumpingJackTop(frame: Frame) -> Float {
        
    let skeleton = frame.skeleton
    let rightArmAngle = getAngleFromXYZ(endPoint: skeleton.rightHand, origin: skeleton.rightShoulder, relativePlane: Plane.XZ)
    let leftArmAngle = getAngleFromXYZ(endPoint: skeleton.leftHand, origin: skeleton.leftShoulder, relativePlane: Plane.XZ)
    
    // The max score for the top position is when the arm angles are as close to 90 as possible
    let score = (pow(rightArmAngle, 2) + pow(leftArmAngle, 2))
    
    // Since we are squaring to get the score, we must check if the angles are negative (and thus the 'bottom' JJ position)
    if( rightArmAngle < 0.0 && leftArmAngle < 0.0) {
        return -1*score
    }
    
    return score
}


func scoreJumpingJackBottom(frame: Frame) -> Float {
        
    let skeleton = frame.skeleton
    let rightArmAngle = getAngleFromXYZ(endPoint: skeleton.rightHand, origin: skeleton.rightShoulder, relativePlane: Plane.XZ)
    let leftArmAngle = getAngleFromXYZ(endPoint: skeleton.leftHand, origin: skeleton.leftShoulder, relativePlane: Plane.XZ)
    
    // The max score for the top position is when the arm angles are as close to 90 as possible
    let score = (pow(rightArmAngle, 2) + pow(leftArmAngle, 2))
    
    // Since we are squaring to get the score, we must check if the angles are negative (and thus the 'bottom' JJ position)
    if( rightArmAngle > 0.0 && leftArmAngle > 0.0) {
        return -1*score
    }
    
    return score
}


struct JumpingJackScores{
    var top: Float
    var mid: Float
    var bottom: Float
}

func scoreJumpingJack(frames: [Frame]) -> [JumpingJackScores] {
    
    var scores = JumpingJackScores(top: 0.0, mid: 0.0, bottom: 0.0)
    var all_scores = [JumpingJackScores]()
    
    for frame in frames{
        scores.top = scoreJumpingJackTop(frame: frame)
        scores.mid = scoreJumpingJackMiddle(frame: frame)
        scores.bottom = scoreJumpingJackBottom(frame: frame)
        all_scores.append(scores)
    }
    
    return all_scores
}

func printJJ(scores: [JumpingJackScores]){
    for score in scores {
        print("\(score.top) \(score.mid) \(score.bottom)")
    }
}

class ViewController: UIViewController, ARSessionDelegate, RPPreviewViewControllerDelegate {
    
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var recordButtonView: UIView!
    @IBOutlet var arView: ARView!
    @IBOutlet var timerView: UIView!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet weak var rightHandAngleLabel: UILabel!
    @IBOutlet weak var leftHandleAngleLabel: UILabel!
    @IBOutlet weak var rightFootAngleLabel: UILabel!
    @IBOutlet weak var leftFootAngleLabel: UILabel!
    @IBOutlet weak var neutralScore: UILabel!
    @IBOutlet weak var topScore: UILabel!
    @IBOutlet weak var bottomScore: UILabel!
    
    var printoutText: String = ""
    
    // controls recording
    var isRecording = false
    let recorder = RPScreenRecorder.shared()
    var recordedFrames = [Frame].init()
    
    // attempting to bypass preview view controller:
    var videoOutputURL: URL = URL(fileURLWithPath: "")
    var videoWriter: AVAssetWriter?
    var videoWriterInput: AVAssetWriterInput?

    var timer: Timer?
    var timeElapsed: Double = 0.0
    var milliseconds: Int = 0
    
    @IBAction func recordPressed(_ sender: Any) {
        if let button = sender as? UIButton {
            button.pulse()
        }
        isRecording = !isRecording
        updateButtonState()
    }
    
    func updateButtonState() {
        if isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    // attempting to record without presenting preview view controller: https://stackoverflow.com/questions/33484101/how-to-save-replaykit-video-to-camera-roll-with-in-app-button?rq=1
    /*
       @objc func startScreenRecording() {
           //Use ReplayKit to record the screen

           //Create the file path to write to
           let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
           self.videoOutputURL = URL(fileURLWithPath: documentsPath.appendingPathComponent("MyVideo.mp4"))

           //Check the file does not already exist by deleting it if it does
           do {
               try FileManager.default.removeItem(at: videoOutputURL)
           } catch {}


           do {
               try videoWriter = AVAssetWriter(outputURL: videoOutputURL, fileType: AVFileType.mp4)
           } catch let writerError as NSError {
               print("Error opening video file", writerError)
               videoWriter = nil
               return
           }

           //Create the video settings
           let videoSettings: [String : Any] = [
               AVVideoCodecKey  : AVVideoCodecType.h264,
               AVVideoWidthKey  : 1920,  //Replace as you need
               AVVideoHeightKey : 1080   //Replace as you need
           ]

           //Create the asset writer input object whihc is actually used to write out the video
           //with the video settings we have created
           videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
           
           // NBY: safe to do guard let for videoWriter and videoWriterInput?
           guard let videoWriter = videoWriter else { return }
           guard let videoWriterInput = videoWriterInput else { return }
           
           videoWriter.add(videoWriterInput)

           //Tell the screen recorder to start capturing and to call the handler when it has a
           //sample
           RPScreenRecorder.shared().startCapture(handler: { (cmSampleBuffer, rpSampleType, error) in

               guard error == nil else {
                   //Handle error
                   print("Error starting capture")
                   return
               }

               switch rpSampleType {
                   case RPSampleBufferType.video:
                       print("writing sample....")
                       if self.videoWriter.status == AVAssetWriter.Status.unknown {

                           if (( self.videoWriter?.startWriting ) != nil) {
                               print("Starting writing")
                               self.videoWriter.startWriting()
                               self.videoWriter.startSession(atSourceTime:  CMSampleBufferGetPresentationTimeStamp(cmSampleBuffer))
                           }
                       }

                       if self.videoWriter.status == AVAssetWriter.Status.writing {
                           if (self.videoWriterInput.isReadyForMoreMediaData == true) {
                               print("Writing a sample")
                               if  self.videoWriterInput.append(cmSampleBuffer) == false {
                                   print(" we have a problem writing video")
                               }
                           }
                   }

                   default:
                       print("not a video sample, so ignore")
               }
           } )
       }

       @objc func stopScreenRecording() {
           //Stop Recording the screen
           RPScreenRecorder.shared().stopCapture( handler: { (error) in
               print("stopping recording")
           })
           
           self.videoWriterInput.markAsFinished()
           self.videoWriter.finishWriting {
               print("finished writing video")

               //Now save the video
               PHPhotoLibrary.shared().performChanges({
                   PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoOutputURL)
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
       */
    
    func startRecording() {
        // https://www.appcoda.com/replaykit/
        guard recorder.isAvailable else {
            print("Recording is not available at this time.")
            return
        }
        
        recorder.startRecording { [unowned self] (error) in
            
            guard error == nil else {
                print("There was an error starting the recording.")
                return
            }
            
            print("Started Recording Successfully")
            
            self.clearFramesList()
            self.isRecording = true
            self.presentTimer()
            self.recordButton.setTitle("Stop", for: .normal)
            self.recordButton.layer.cornerRadius = 10
            self.recordButtonView.layer.cornerRadius = 10
//            self.recordButtonView.animateCornerRadius(from: self.recordButtonView.layer.frame.height / 2, to: 10, duration: 0.25)
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            })
        }
        
    }
    
    func stopRecording() {
        // https://www.appcoda.com/replaykit/
        recorder.stopRecording { [unowned self] (preview, error) in
            print("Stopped recording")
            
            guard preview != nil else {
                print("Preview controller is not available.")
                return
            }
            
            let alert = UIAlertController(title: "Recording Finished", message: "Would you like to edit or delete your recording?", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction) in
                self.recorder.discardRecording(handler: { () -> Void in
                    print("Recording suffessfully deleted.")
                })
            })
            
            let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action: UIAlertAction) -> Void in
                preview?.previewControllerDelegate = self
                self.present(preview!, animated: true, completion: nil)
            })
            
            // how to bypass preview view controller?!
            let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in
                print("saved")
            }
            
            alert.addAction(editAction)
            alert.addAction(deleteAction)
            self.present(alert, animated: true, completion: nil)
            
            let scores = scoreJumpingJack(frames: self.recordedFrames)
            
            printJJ(scores: scores)
            
            // reset timer, record button
            self.isRecording = false
            
            saveFrame(frames: self.recordedFrames)
            
            
            
            self.timer?.invalidate()
            self.milliseconds = 0
            self.hideTimer()
            self.recordButton.setTitle("Start", for: .normal)
            self.recordButton.layer.cornerRadius = self.recordButton.layer.frame.height / 2
            self.recordButtonView.layer.cornerRadius = self.recordButtonView.layer.frame.height / 2
//            self.recordButtonView.animateCornerRadius(from: 10, to: self.recordButtonView.layer.frame.height / 2, duration: 0.25)
            
//            self.performSegue(withIdentifier: "toReview", sender: self)
        }
    }
    
    func saveText() {
        // writes the string printoutText to a file locally and presents an alert upon completion/error
        let filename = getDocumentsDirectory().appendingPathComponent("output.txt")

        do {
            try self.printoutText.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
            let alert = UIAlertController(title: "Success!", message: "Joint transforms saved to file", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            let alert = UIAlertController(title: "Error", message: "Unable to save joint transforms to file", preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
        }
        self.printoutText = ""
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
        performSegue(withIdentifier: "toReview", sender: self)
    }
    
    func updateTimerLabel() {
        
        var toDisplay = ""
        milliseconds += 1
        if (milliseconds / 100) < 10 {
            toDisplay = "0\(milliseconds / 100) : \(milliseconds % 100)"
        } else {
            toDisplay = "\(milliseconds / 100):\(milliseconds % 100)"
        }
        self.timerLabel.text = toDisplay
    }
    
    func presentTimer() {
        UIView.animate(withDuration: 0.5) {
            self.timerView.alpha = 0.75
            self.timerLabel.alpha = 1
        }
    }
    
    func hideTimer() {
        UIView.animate(withDuration: 0.5) {
            self.timerView.alpha = 0
            self.timerLabel.alpha = 0
        }
    }
    
    // placeholder for ReplayKit functionality
    func saveRecording() {
        let alertViewController = UIAlertController(title: "Recording Saved", message: "New \(milliseconds / 100)-second recording has been saved to camera roll", preferredStyle: .alert)
        let action = UIAlertAction(title: "Okay!", style: .default, handler: nil)
        alertViewController.addAction(action)
        self.present(alertViewController, animated: true, completion: {
//            self.performSegue(withIdentifier: "toReview", sender: self)
        })
    }
    
    
    @IBAction func restartPressed(_ sender: Any) {
        printoutText = ""
    }
    
    // The 3D character to display.
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [-0.3, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    
    override func viewDidLoad() {
        recordButton.layer.masksToBounds = true
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.backgroundColor = .red
        recordButton.setTitle("Start", for: .normal)
        recordButton.layer.cornerRadius = recordButton.layer.frame.height / 2
        
        recordButtonView.layer.masksToBounds = true
        recordButtonView.layer.cornerRadius = recordButtonView.layer.frame.height / 2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        
        // If the iOS device doesn't support body tracking, raise a developer error for
        // this unhandled case.
        guard ARBodyTrackingConfiguration.isSupported else {
            fatalError("This feature is only supported on devices with an A12 chip")
        }
        
        // Run a body tracking configration.
        let configuration = ARBodyTrackingConfiguration()
        
        configuration.automaticImageScaleEstimationEnabled = true
        
        arView.session.run(configuration)
        
        arView.scene.addAnchor(characterAnchor)
        
        // Asynchronously load the 3D character.
        var cancellable: AnyCancellable? = nil
        cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: Unable to load model: \(error.localizedDescription)")
                }
                cancellable?.cancel()
        }, receiveValue: { (character: Entity) in
            if let character = character as? BodyTrackedEntity {
                // Scale the character to human size
                character.scale = [1.0, 1.0, 1.0]
                self.character = character
                cancellable?.cancel()
            } else {
                print("Error: Unable to load model as BodyTrackedEntity")
            }
        })
    }
    
    func writeAnchor(anchor: ARAnchor) {
        // adding to a string
        // goal is to save the knee transform
        printoutText += "\n anchor name: \(String(describing: anchor.name))"
        printoutText += "\n anchor description: \(anchor.description)"
        printoutText += "\n anchor transform: \(anchor.transform)"
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
            // Write data to text view — performance nightmare
            writeAnchor(anchor: bodyAnchor)
            
            // Update the position of the character anchor's position.
            let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition + characterOffset
            
            // Also copy over the rotation of the body anchor, because the skeleton's pose
            // in the world is relative to the body anchor's rotation.
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
            
//            // Do some math
//            let rightHandAngle = makeDegreeStringPretty(deg: getRightHandAngle(bodyAnchor: bodyAnchor))
//
//            // Do some math
//            let leftHandAngle = makeDegreeStringPretty(deg: getLeftHandAngle(bodyAnchor: bodyAnchor))
//
//            let rightFootAngle = makeDegreeStringPretty(deg: getRightLegAngle(bodyAnchor: bodyAnchor))
//
            // Do some math
              // Do some math
            // Update label

            let frame = Frame(arSkeleton: bodyAnchor.skeleton, timestamp: milliseconds)

            let rightHandAngle = makeDegreeStringPretty(deg: getAngleFromXYZ(endPoint: frame.skeleton.rightHand , origin: frame.skeleton.rightShoulder, relativePlane: Plane.XZ))
              
            let leftHandAngle = makeDegreeStringPretty(deg: getAngleFromXYZ(endPoint: frame.skeleton.leftHand, origin: frame.skeleton.leftShoulder, relativePlane: Plane.XZ))
            
            let rightFootAngle = makeDegreeStringPretty(deg: getAngleFromXYZ(endPoint: frame.skeleton.rightFoot, origin: frame.skeleton.hip, relativePlane: Plane.XZ))
            let leftFootAngle = makeDegreeStringPretty(deg: getAngleFromXYZ(endPoint: frame.skeleton.leftFoot, origin: frame.skeleton.hip, relativePlane: Plane.XZ))
                
            
            // Score each frame on the 3 'snapshots' of a JJ
            let jjNeutralScore = scoreJumpingJackMiddle(frame: frame)
            let jjBottomScore = scoreJumpingJackBottom(frame: frame)
            let jjTopScore = scoreJumpingJackTop(frame: frame)
            
            self.rightHandAngleLabel.text = "Right Hand " + String(describing: rightHandAngle)
            self.leftHandleAngleLabel.text = "Left Hand " + String(describing: leftHandAngle)
            self.rightFootAngleLabel.text = "Right Foot " + String(describing: rightFootAngle)
            self.leftFootAngleLabel.text = "Left Foot " + String(describing: leftFootAngle)
            
            self.neutralScore.text = String(describing: frame.skeleton.rightHand)
            self.topScore.text = String(describing: frame.skeleton.rightShoulder)
            self.bottomScore.text = String(describing: jjBottomScore)
            
            if(self.isRecording){
                addFrameToList(frame: frame)
            }
            
            if let character = character, character.parent == nil {
                // Attach the character to its anchor as soon as
                // 1. the body anchor was detected and
                // 2. the character was loaded.
                characterAnchor.addChild(character)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toReview" {
            if let dest = segue.destination as? ReviewViewController {
                if printoutText.count == 0 {
                    dest.transformPrintout = "No transform data collected during analysis."
                } else {
                    dest.transformPrintout = printoutText
                }
            }
        }
    }
    
    func makeDegreeStringPretty(deg: Float) -> String {
        let s = Float(floor(10 * deg) / 10)
        return "\(s) degrees"
    }

    
    func clearFramesList(){
        recordedFrames.removeAll()
    }
    
    func addFrameToList(frame: Frame){
        recordedFrames.append(frame)
    }
//    func scoreJJMidPosition(frame: Frame){
//        let right_hand_angle = getRightLegAngle(bodyAnchor: frame.skeleton.)
////        let left_hand_angle = getLeftHandAngle(bodyAnchor: frame.skeleton)
//    }
}
