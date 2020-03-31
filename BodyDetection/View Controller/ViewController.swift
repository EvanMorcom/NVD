import UIKit
import RealityKit
import ARKit
import Combine
import ReplayKit
import Photos


let MAX_HAND_ANGLE = 65.0 // degrees
let TOP_SCORE_THRESHHOLD = 5000.0
let MIDDLE_SCORE_THRESHHOLD = 6000.0
let BOTTOM_SCORE_THRESHHOLD = 3000.0


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
        //print(jsonString)
    } catch { print(error) }
}

func makeDegreeStringPretty(deg: Float) -> String {
    let s = Int(floor(deg))
    return "\(s) degrees"
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
    let max_deviation = pow(Float(MAX_HAND_ANGLE), 2) + pow(Float(MAX_HAND_ANGLE), 2)
    let score =  (max_deviation - (pow(rightArmAngle, 2) + pow(leftArmAngle, 2)))
    
    return score
}

func reverseScoreJumpingJackMiddle(score: Float) -> Float {
        
    // The max score for the neutral position is when the arm angles are as close to zero as possible
    let max_deviation = pow(Float(MAX_HAND_ANGLE), 2) + pow(Float(MAX_HAND_ANGLE), 2)
    let angle = sqrt( abs((score - max_deviation)/(-2.0)))
    return angle
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

func reverseScoreJumpingJackTop(score: Float) -> Float {
    let angle = sqrt(abs(score/2.0))
    return angle
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

func reverseScoreJumpingJackBottom(score: Float) -> Float {
    
    let angle = sqrt(abs(score/2.0))
    
    return angle
}


struct JumpingJackScores{
    var top: Float
    var mid: Float
    var bottom: Float
}

func scoreJumpingJack(frames: [Frame]) -> [[Float]] {
    
    var topScores = [Float]()
    var middleScores = [Float]()
    var bottomScores = [Float]()
    
    
    for frame in frames{
        topScores.append(scoreJumpingJackTop(frame: frame))
        middleScores.append(scoreJumpingJackMiddle(frame: frame))
        bottomScores.append(scoreJumpingJackBottom(frame: frame))
    }
    
    return [topScores, middleScores, bottomScores]
}

extension Collection where Element: Comparable {
    func localMaxima() -> [Element] {
        return localMaxima(in: startIndex..<endIndex)
    }

    func localMaxima(in range: Range<Index>) -> [Element] {
        var slice = self[range]
        var maxima = [Element]()

        var previousIndex: Index? = nil
        var currentIndex = slice.startIndex
        var nextIndex = slice.index(after: currentIndex)

        while nextIndex < slice.endIndex {
            defer {
                previousIndex = currentIndex
                currentIndex = nextIndex
                nextIndex = slice.index(after: nextIndex)
            }

            let current = slice[currentIndex]
            let next = slice[nextIndex]

            // For the first element, there is no previous
            if previousIndex == nil {
                if Swift.max(current, next) == current {
                    maxima.append(current)
                }
                continue
            }

            // For the last element, there is no next
            if nextIndex == slice.endIndex {
                let previous = slice[previousIndex!]
                if Swift.max(previous, current) == current {
                    maxima.append(current)
                }
                continue
            }

            let previous = slice[previousIndex!]

            let maximum = Swift.max(previous, current, next)
            // magnitudes[i] is a peak iff it's greater than it's surrounding points
            if maximum == current && current != next {
                maxima.append(current)
            }
        }
        return maxima
    }
}

var topFeedbackAngle = Float(0.0)
var bottomFeedbackAngle = Float(0.0)
var middleFeedbackAngle = Float(0.0)

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
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            })
        }
        
    }
    
    func stopRecording() {
        recorder.stopRecording { [unowned self] (preview, error) in
            print("Stopped recording")
            
            guard preview != nil else {
                print("Preview controller is not available.")
                return
            }
            
            let alert = UIAlertController(title: "Analysis Finished", message: "Would you like to review or delete your Analysis?", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction) in
                self.recorder.discardRecording(handler: { () -> Void in
                    print("Recording suffessfully deleted.")
                })
            })
            
            let editAction = UIAlertAction(title: "Review", style: .default, handler: { (action: UIAlertAction) -> Void in
                preview?.previewControllerDelegate = self
                self.present(preview!, animated: true, completion: nil)
                alert.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "feedback Here"
                }})
            
            let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in
                print("saved")
            }
            
            alert.addAction(editAction)
            alert.addAction(deleteAction)

            self.present(alert, animated: true, completion: nil)
            let feedback_popup = UIAlertController(title: "Feedback", message: "Do better", preferredStyle: .alert)
                 
            self.present(feedback_popup, animated: true, completion: nil)
                 
            let scores = scoreJumpingJack(frames: self.recordedFrames)
            
            for i in 0..<scores[0].count{
                print( "\(scores[0][i]) \(scores[1][i]) \(scores[2][i])")
            }
            
            let topMaximums = scores[0].localMaxima()
            var sum = Float(0.0)
            var count = 0;
            for s in topMaximums{
                if(s >= Float(TOP_SCORE_THRESHHOLD)){
                    sum = sum + s
                    count+=1
                }
            }
            sum = sum/Float(count);
            self.topScore.text = String(describing: sum)
            topFeedbackAngle = abs( Float(MAX_HAND_ANGLE) - reverseScoreJumpingJackTop(score: sum))
            
            let middleMaximums = scores[1].localMaxima()
            sum = 0.0
            count = 0;
            for s in middleMaximums{
                if(s >= Float(MIDDLE_SCORE_THRESHHOLD)) {
                     sum = sum + s
                    count+=1
                 }
            }
            sum = sum/Float(count)
            self.neutralScore.text = String(describing: sum)
            middleFeedbackAngle = reverseScoreJumpingJackMiddle(score: sum)
            
            let bottomMaximums = scores[2].localMaxima()
            sum = 0.0
            count = 0
            for s in bottomMaximums{
                if(s >= Float(BOTTOM_SCORE_THRESHHOLD) ){
                     sum = sum + s
                     count+=1
                 }
            }
            sum = sum/Float(count)
            self.bottomScore.text = String(describing: sum)
            bottomFeedbackAngle = abs( Float(MAX_HAND_ANGLE) - reverseScoreJumpingJackBottom(score: sum))
            
            // reset timer, record button
            self.isRecording = false
            
            saveFrame(frames: self.recordedFrames)
            
            let maxScores = scoreJumpingJack(frames: self.recordedFrames)
        
            self.timer?.invalidate()
            self.milliseconds = 0
            self.hideTimer()
            self.recordButton.setTitle("Start", for: .normal)
            self.recordButton.layer.cornerRadius = self.recordButton.layer.frame.height / 2
            self.recordButtonView.layer.cornerRadius = self.recordButtonView.layer.frame.height / 2
            
        }
    }
    
    func saveText() {
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
    
    func saveRecording() {
        let alertViewController = UIAlertController(title: "Recording Saved", message: "New \(milliseconds / 100)-second recording has been saved to camera roll", preferredStyle: .alert)
        let action = UIAlertAction(title: "Okay!", style: .default, handler: nil)
        alertViewController.addAction(action)
        self.present(alertViewController, animated: true, completion: {
        })
    }
    
    
    @IBAction func restartPressed(_ sender: Any) {
        printoutText = ""
    }
    
    var character: BodyTrackedEntity?
    let characterOffset: SIMD3<Float> = [-0.3, 0, 0]
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

            let frame = Frame(arSkeleton: bodyAnchor.skeleton, timestamp: milliseconds)

            let rightHandAngle = makeDegreeStringPretty(deg: getAngleFromXYZ(endPoint: frame.skeleton.rightHand , origin: frame.skeleton.rightShoulder, relativePlane: Plane.XZ))
              
            let leftHandAngle = makeDegreeStringPretty(deg: getAngleFromXYZ(endPoint: frame.skeleton.leftHand, origin: frame.skeleton.leftShoulder, relativePlane: Plane.XZ))
            
            let rightFootAngle = makeDegreeStringPretty(deg: getAngleFromXYZ(endPoint: frame.skeleton.rightFoot, origin: frame.skeleton.hip, relativePlane: Plane.XZ))
            let leftFootAngle = makeDegreeStringPretty(deg: getAngleFromXYZ(endPoint: frame.skeleton.leftFoot, origin: frame.skeleton.hip, relativePlane: Plane.XZ))
                
            self.rightHandAngleLabel.text = "Right Hand " + String(describing: rightHandAngle)
            self.leftHandleAngleLabel.text = "Left Hand " + String(describing: leftHandAngle)
            self.rightFootAngleLabel.text = "Right Foot " + String(describing: rightFootAngle)
            self.leftFootAngleLabel.text = "Left Foot " + String(describing: leftFootAngle)
            
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
    

    
    func clearFramesList(){
        recordedFrames.removeAll()
    }
    
    func addFrameToList(frame: Frame){
        recordedFrames.append(frame)
    }
}
