//
//  ViewController.swift
//  Pictures
//
//  Created by Collin Klenke on 6/6/17.
//  Copyright © 2017 Collin Klenke. All rights reserved.
//

import UIKit
import Speech
import GameKit

extension Array {
    mutating func shuffle() {
        for i in 0..<(count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            if(i != j){
                swap(&self[i], &self[j])
            }
        }
    }
}

class PhotosViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    
    @IBOutlet weak var topleft: UIImageView!
    @IBOutlet weak var topright: UIImageView!
    @IBOutlet weak var center: UIImageView!
    @IBOutlet weak var bottomleft: UIImageView!
    @IBOutlet weak var bottomright: UIImageView!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var BeginButton: UIButton!
    @IBOutlet weak var countDownLabel: UILabel!
    
    var timer = Timer()
    var countdown = Timer()
    var hideTimer = Timer()
    var countDownCount: Int = 60
    
    var images: [UIImage] = [
        UIImage(named: "Giraffe")!,
        UIImage(named: "Elephant")!,
        UIImage(named: "Flamingo")!
    ]
    
    var imageStrings: [String] = [
        "giraffe",
        "elephant",                 //important to keep these lowercase
        "flamingo"
    ]
    
    var stringToGuess: String = ""
    
    var arrayIndex: [Int] = Array(0...2)
    var correct: Int = 0
    var incorrect: Int = 0
    var lastPos: Int = 6

    
    //vars used for recording and recognizing speech
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.hideImages()
        self.arrayIndex.shuffle()
        self.requestSpeechAuthorization()
        self.center.center = self.view.center
        self.BeginButton.center.x = self.view.center.x
        self.countDownLabel.text = String(format: "%d", self.countDownCount)
        self.introLabel.adjustsFontSizeToFitWidth = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func beginButtonPressed(_ sender: UIButton){
        self.BeginButton.isHidden = true
        self.introLabel.isHidden = true
        self.countdown = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countDown), userInfo: nil, repeats: true)
        self.recordAndRecognizeSpeech()
        self.generateImage()
        
    }
    
    func countDown(){ //this function updates the countdown every .1 seconds
        self.countDownCount = self.countDownCount - 1
        //if the countdown is 0 - the game is over
        if(self.countDownCount < 0){
            self.countDownLabel.text = "0"
            self.endGame()
            return
        }
        self.countDownLabel.text = String(format: "%d", self.countDownCount)
    }
    
    func requestSpeechAuthorization(){
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus{
                case .authorized:
                    self.introLabel.text = "Press start to begin"
                    self.BeginButton.isEnabled = true
                case .denied:
                    self.BeginButton.isEnabled = false
                    self.introLabel.text = "User denied access to speech recognition"
                case .restricted:
                    self.BeginButton.isEnabled = false
                    self.introLabel.text = "Speech recognition is restricted on this device"
                case .notDetermined:
                    self.BeginButton.isEnabled = false
                    self.introLabel.text = "Speech recognition not yet authorized"
                }
            }
            
        }
    }
    
    func hideImages(){
        self.topright.isHidden = true
        self.topleft.isHidden = true
        self.center.isHidden = true
        self.bottomleft.isHidden = true
        self.bottomright.isHidden = true
    }
    
    func generateImage(){
        if(self.arrayIndex.isEmpty){
            self.endGame()
            return
        }
        let i = Int(self.arrayIndex.removeFirst())
        var pos = Int(arc4random()%5)
        while (pos == self.lastPos){
            pos = Int(arc4random()%5)
        }
        self.lastPos = pos
        
        self.stringToGuess = self.imageStrings[i]
        
        switch pos{
        case 0:
            self.topleft.image = self.images[i]
            self.topleft.isHidden = false
        case 1:
            self.topright.image = self.images[i]
            self.topright.isHidden = false
        case 2:
            self.center.image = self.images[i]
            self.topright.isHidden = false
        case 3:
            self.bottomleft.image = self.images[i]
            self.bottomleft.isHidden = false
        case 4:
            self.bottomright.image = self.images[i]
            self.bottomright.isHidden = false
        default:
            self.hideImages()
            self.endGame()
        }
        self.hideTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(hideImages), userInfo: nil, repeats: false)
    }
    
    func checkWord(spokenWord: String){
        
        //potentially filter the words here, return if its not part of a group of strings or something
        
        if(self.stringToGuess == spokenWord){
            self.correct += 1
        } else {
            self.incorrect += 1
        }
        //self.hideImages()
        print("word to say: \(self.stringToGuess) word guessed: \(spokenWord) correct: \(self.correct) incorrect: \(self.incorrect)")
        
        self.generateImage()
        //self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(generateImage), userInfo: nil, repeats: false)
        
    }
    
    func endGame(){
        audioEngine.stop()
        request.endAudio()
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        self.countDownLabel.isHidden = true
        self.hideImages()
        self.introLabel.text = "Correct: \(self.correct) out of \(self.correct + self.incorrect)"
        self.introLabel.isHidden = false
        
    }
    
    //this function is used to record audio and transform it into a string
    func recordAndRecognizeSpeech(){
        guard let node = audioEngine.inputNode else {return}
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            //recognizer not supported
            return
        }
        if !myRecognizer.isAvailable {
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: {result, error in
            if let result = result {
                var lastWord: String = ""
                let bestString = result.bestTranscription.formattedString
                
                //the audio API appens to a string each with each word the user says, so we need this loop to get the last word spoken - the newest color
                for segment in result.bestTranscription.segments {
                    let index = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastWord = bestString.substring(from: index)
                }
                //debugging print to console
                print(lastWord.lowercased())
                self.checkWord(spokenWord: lastWord.lowercased())
                
            } else if let error = error {
                print(error)
            }
        })
    }

}

