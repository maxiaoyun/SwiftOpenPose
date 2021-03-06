import UIKit
import CoreML
//import CoreMLHelpers
import Upsurge

class ViewController: UIViewController {
    
//    let model = coco_pose_368()
    let model = MobileOpenPose()
    let ImageWidth = 368
    let ImageHeight = 368
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("========")
//        if let image = UIImage(named: "hadou.jpg"){
//            print(measure(runJsonFile(image)).duration)
//        }
        
        let fname = "hadou.jpg"
//        let fname = "lifting"
//        let fname = "person1.jpg"
        if let image = UIImage(named: fname){
            print(measure(runCoreML(image)).duration)
        }
    }
    
    func measure <T> (_ f: @autoclosure () -> T) -> (result: T, duration: String) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = f()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, "Elapsed time is \(timeElapsed) seconds.")
    }
    
    func runJsonFile(_ image: UIImage) {
        imageView.image = image
        
        let url = Bundle.main.url(forResource: "hadou", withExtension: "bin")!
        let text2 = try? String(contentsOf: url, encoding: .utf8)
        let personalData: Data = text2!.data(using: String.Encoding.utf8)!
        let json = try? JSONSerialization.jsonObject(with: personalData, options: [])
        
        if let array = json as? [Double] {
            
            var m: Array<Double> = Array()
            for i in 0..<array.count {
                m.append(Double(array[i]))
            }
            
            drewLine(m)
        }
    }
    
    func runCoreML(_ image: UIImage) {
        
        if let pixelBuffer = image.pixelBuffer(width: ImageWidth, height: ImageHeight) {
            
            let startTime2 = CFAbsoluteTimeGetCurrent()
            if let prediction = try? model.prediction(image: pixelBuffer) {
                
                let timeElapsed2 = CFAbsoluteTimeGetCurrent() - startTime2
                print("coreml elapsed for \(timeElapsed2) seconds")
                
                // view
                imageView.image = UIImage(pixelBuffer: pixelBuffer)
                
//                let pred = prediction.MConv_Stage7_concat
                let pred = prediction.net_output
                let length = pred.count
//                print(length)
                print(pred)
                
                let doublePtr =  pred.dataPointer.bindMemory(to: Double.self, capacity: length)
                let doubleBuffer = UnsafeBufferPointer(start: doublePtr, count: length)
                let mm = Array(doubleBuffer)
//                print(mm)
                drewLine(mm)
            }
        }
    }
    
    func drewLine(_ mm: Array<Double>){
        
        let com = PoseEstimator(ImageWidth,ImageHeight)
        
        let h = imageView.image?.size.height
        let imageH = Int(h!)
        let w = imageView.image?.size.width
        let imageW = Int(w!)
        
        let res = measure(com.estimate(mm))
        let humans = res.result;
        print("estimate \(res.duration)")
        
        for human in humans {
            var centers = [Int: CGPoint]()
            for i in 0...CocoPart.Background.rawValue {
                if human.bodyParts.keys.index(of: i) == nil {
                    continue
                }
                let bodyPart = human.bodyParts[i]!
                centers[i] = CGPoint(x: Int(bodyPart.x * CGFloat(imageW) + 0.5), y: Int(bodyPart.y * CGFloat(imageH) + 0.5))
            }
            for (pairOrder, (pair1,pair2)) in CocoPairsRender.enumerated() {
                if human.bodyParts.keys.index(of: pair1) == nil || human.bodyParts.keys.index(of: pair2) == nil {
                    continue
                }
                if centers.index(forKey: pair1) != nil && centers.index(forKey: pair2) != nil{
                    addLine(fromPoint: centers[pair1]!, toPoint: centers[pair2]!, color: CocoColors[pairOrder])
                }
            }
        }
    }
    
    func addLine(fromPoint start: CGPoint, toPoint end:CGPoint, color: UIColor) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        line.strokeColor = color.cgColor
        line.lineWidth = 3
        line.lineJoin = kCALineJoinRound
        self.view.layer.addSublayer(line)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
