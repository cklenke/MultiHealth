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

//this is to shuffle the index array we make
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
    
    //storyboard elements
    @IBOutlet weak var topleft: UIImageView!
    @IBOutlet weak var topright: UIImageView!
    @IBOutlet weak var center: UIImageView!
    @IBOutlet weak var bottomleft: UIImageView!
    @IBOutlet weak var bottomright: UIImageView!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var BeginButton: UIButton!
    @IBOutlet weak var countDownLabel: UILabel!
    
    //timing variables - used to set timers
    var timer = Timer()
    var countdown = Timer()
    var hideTimer = Timer()
    var countDownCount: Int = 60
    
    //this is the array of images - to add more simply add a comma and copy the format of the one above
    //then drag the image with xxx.png name into the Assets.xcassets folder in the project navigator on the left
    var images: [UIImage] = [
        UIImage(named: "Giraffe")!,
        UIImage(named: "Elephant")!,
        UIImage(named: "Flamingo")!
    ]
    
    //2D array of strings - each row is for a different image
    var imageStrings: [[String]] = [
        ["giraffe", "mammal", "animal"],
        ["elephant", "animal"],                 //important to keep these lowercase
        ["flamingo", "bird"]
    ]
    
    var stringToGuess: [String] = []
    
    //create an array to pick which image is next
    var arrayIndex: [Int] = Array(0...2) //change 2 to n-1 for n pictures
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
    
    //permissions for using the microphone
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
    
    //clears the image off the screen no matter what position it is in
    func hideImages(){
        self.topright.isHidden = true
        self.topleft.isHidden = true
        self.center.isHidden = true
        self.bottomleft.isHidden = true
        self.bottomright.isHidden = true
    }
    
    func generateImage(){
        if(self.arrayIndex.isEmpty){ //avoid issues with not having another image to display, the game should be over
            self.endGame()
            return
        }
        let i = Int(self.arrayIndex.removeFirst())
        var pos = Int(arc4random()%5)
        while (pos == self.lastPos){
            pos = Int(arc4random()%5)               //we want the position to change, so we keep track of the last position and put the next one somewhere else
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
        
        //set timer to hide the image after 1 second
        self.hideTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(hideImages), userInfo: nil, repeats: false)
    }
    
    func checkWord(spokenWord: String){
        
        //potentially filter the words here, return if its not part of a group of strings or something
        
        var cor = 0
        for word in self.stringToGuess {
            if spokenWord == word{          //go through each word it could be and check if it is right
                self.correct += 1
                cor = 1
                break
            }
        }
        if(cor == 0){
            self.incorrect += 1
        }
        //self.hideImages()
        print("word to say: \(self.stringToGuess) word guessed: \(spokenWord) correct: \(self.correct) incorrect: \(self.incorrect)")
        
        self.generateImage()
        //self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(generateImage), userInfo: nil, repeats: false)
        
    }
    
    //clear everything and display results
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
                
                //the audio API appends to a string each with each word the user says, so we need this loop to get the last word spoken - the newest color
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

