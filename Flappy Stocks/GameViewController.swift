//
//  GameViewController.swift
//  Flappy Stocks
//
//  Created by Nathan Cohen on 2/08/2017.
//  Copyright © 2017 Sudo-Code Software. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import SwiftSocket

class GameViewController: UIViewController {
    
    static var drawPath = [Double](repeating: 0.0, count: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Instantiate UDP Client and send server intial connection message
        
        let client = UDPClient(address: "172.20.10.2", port: 5149)
        
        let bytes = [Byte](repeating: 0x01, count: 16)

        
        
        //Instantiate draw class
        
        let screenSize: CGRect = UIScreen.main.bounds
        
        let k = Draw(frame: CGRect(
            origin: CGPoint(x: 0, y: 0),
            size: CGSize(width: screenSize.width, height: screenSize.height)), drawPath: GameViewController.drawPath)
        
        self.view.addSubview(k)


        
        var i = 0
        
        DispatchQueue.global(qos: .background).async {
            while true {
            
                client.send(data: bytes)
            
                //receive UDP stream from server
                let rawData = client.recv(8)
                
                //Change encoding to double so it can be interpreted
                let serverData = rawData.0!.reversed() as [Byte]
                var d = Double()
                memcpy(&d, serverData, 8)
                print(d)
                
                //add new data point to array, remove oldest data point
                GameViewController.drawPath.append(d);
                if (GameViewController.drawPath.count >= 200) {
                    GameViewController.drawPath.remove(at: 0);
                }
                
                DispatchQueue.main.async {
                //redraw screen
                    k.setNeedsDisplay(CGRect(
                        origin: CGPoint(x: 0, y: 0),
                        size: CGSize(width: screenSize.width, height: screenSize.height)))
                    }
                i = i+1
            }
            
            client.close()
        }
    }
    
    

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    class Draw: UIView {
        var mdrawPath: [Double]
        var mYCenter: Double = 0;
        var mYScale: Double = 0.25;
        let mYMoveRate: Double = 0.1;
        
        init(frame: CGRect, drawPath: [Double]) {
            mdrawPath = GameViewController.drawPath
            super.init(frame: frame)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
        override func draw(_ rect: CGRect) {
            
            let screenSize: CGRect = UIScreen.main.bounds
            
            let aPath = UIBezierPath()
            
            
            mdrawPath = GameViewController.drawPath
            
            let lastValue = mdrawPath.last!
            
            mYCenter = mYCenter * (1 - mYMoveRate) + lastValue * mYMoveRate;
            
            UIGraphicsGetCurrentContext()!.clear(UIScreen.main.bounds)
            
            aPath.move(to: CGPoint(x:-10, y:284))
            
            for i in (0...(mdrawPath.count-1)){
                
                let offset = mYScale*(mdrawPath[i] - mYCenter)
                
                aPath.addLine(
                    to: CGPoint(
                        x: CGFloat(i)*(screenSize.width/CGFloat(mdrawPath.count)),
                        y: (screenSize.height/2 + CGFloat(offset))))
            }
            aPath.move(to: CGPoint(x:0, y:284))
            
            //Keep using the method addLineToPoint until you get to the one where about to close the path
            
            aPath.close()
            
            //If you want to stroke it with a red color
            UIColor.red.set()
            aPath.stroke()
            aPath.removeAllPoints()
            //If you want to fill it as well
            //aPath.fill()
            
        }
        
    }
}


