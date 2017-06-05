//
//  ViewController.swift
//  Color Speech
//
//  Created by Collin Klenke on 5/31/17.
//  Copyright © 2017 Collin Klenke. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    //labels and buttons
    @IBOutlet weak var ColorName: UILabel!
    @IBOutlet weak var BeginButton: UIButton!
    @IBOutlet weak var CounterLabel: UILabel!
    
    //timing vars
    var timer = Timer()
    var countdown = Timer()
    var NSStart = NSDate()
    var playerCanGuess = 1
    var countDownCount: Int = 60
    
    //count correct  vs incorrect
    var correct: Int = 0
    var incorrect: Int = 0
    
    //vars used for recording and recognizing speech
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    //used to set/check color of word
    let colorFilter = ["red", "orange", "yellow", "green", "blue", "purple", "black", "white", "grey", "pink"]
    var color: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.requestSpeechAuthorization()
        self.CounterLabel.text = String(format: "%d", self.countDownCount)
        self.ColorName.adjustsFontSizeToFitWidth = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func requestSpeechAuthorization(){
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus{
                case .authorized:
                    self.BeginButton.isEnabled = true
                    self.ColorName.text = "Press start to begin"
                case .denied:
                    self.BeginButton.isEnabled = false
                    self.ColorName.text = "User denied access to speech recognition"
                case .restricted:
                    self.BeginButton.isEnabled = false
                    self.ColorName.text = "Speech recognition is restricted on this device"
                case .notDetermined:
                    self.BeginButton.isEnabled = false
                    self.ColorName.text = "Speech recognition not yet authorized"
                }
            }
            
        }
    }

    @IBAction func BeginButtonPressed(_ sender: UIButton){
        self.BeginButton.isHidden = true
        //this timer is used to measure the countdown clock
        self.countdown = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countDown), userInfo: nil, repeats: true)
        //begin listening on the microphone
        self.recordAndRecognizeSpeech()
        //make the first color
        self.generateColor()
    }
    
    func countDown(){ //this function updates the countdown every .1 seconds
        self.countDownCount = self.countDownCount - 1
        //if the countdown is 0 - the game is over
        if(self.countDownCount < 0){
            self.CounterLabel.text = "0"
            self.endGame()
            return
        }
        self.CounterLabel.text = String(format: "%d", self.countDownCount)
    }
    
    func endGame(){
        //stop recording audio - avoid crash at just over 60s
        audioEngine.stop()
        request.endAudio()
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        //display results
        self.ColorName.textColor = UIColor.black
        self.ColorName.text = "Correct: \(self.correct) out of \(self.correct + self.incorrect)"
        self.ColorName.isHidden = false
    }
    
    //this function chooses what color and what color name will be displayed
    func generateColor(){
        let colorWord = Int(arc4random()%7)
        self.color = Int(arc4random()%7)
        //this while loop avoids having red be displayed in red etc
        while(self.color == colorWord){
            self.color = Int(arc4random()%7)
        }
        
        var colorString: String = ""
        
        switch colorWord {
        case 0:
            colorString = "red"
        case 1:
            colorString = "orange"
        case 2:
            colorString = "yellow"
        case 3:
            colorString = "green"
        case 4:
            colorString = "blue"
        case 5:
            colorString = "purple"
        case 6:
            colorString = "black"
        default:
            break
        }
        
        switch self.color{
        case 0:
            self.ColorName.textColor = UIColor.red
        case 1:
            self.ColorName.textColor = UIColor.orange
        case 2:
            self.ColorName.textColor = UIColor.yellow
        case 3:
            self.ColorName.textColor = UIColor.green
        case 4:
            self.ColorName.textColor = UIColor.blue
        case 5:
            self.ColorName.textColor = UIColor.purple
        case 6:
            self.ColorName.textColor = UIColor.black
        default:
            break
        }
        
        
        self.ColorName.text = colorString
        self.ColorName.isHidden = false
        
        //set playerCanGuess to 1 so that what they say will be recognized
        self.playerCanGuess = 1
        //begin the timer for how long it takes the user to say the color
        self.NSStart = NSDate()
        
    }
    
    //this checks if the color the user says is right or wrong
    func colorCheck(spokenWord: String){
        var colorString: String = ""
        
        if self.playerCanGuess == 0{
            return
        }
        
        //self.color is a global var set in generateColor() - set a string to compare to the color spoken by user
        switch self.color{
        case 0:
            colorString = "red"
        case 1:
            colorString = "orange"
        case 2:
            colorString = "yellow"
        case 3:
            colorString = "green"
        case 4:
            colorString = "blue"
        case 5:
            colorString = "purple"
        case 6:
            colorString = "black"
        default:
            break
        }
        
        //time since the color was generated
        let interval = abs(self.NSStart.timeIntervalSinceNow)
        
        if colorString == spokenWord{
            //correct!
            self.correct += 1
        } else {
            //incorrect
            self.incorrect += 1
        }
        print("Correct: \(self.correct) Incorrect: \(self.incorrect) Time: \(interval) seconds") //to console, but this info can be used elsewhere if necessary
        
        //hide the label so the user knows what they said registered in the device
        self.ColorName.isHidden = true
        //set bool to 0 to avoid unnecessary executions of color check which might affect users scores
        self.playerCanGuess = 0
        
        //set a timer for 1 second - then generate a new color combo once the 1s is over
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(generateColor), userInfo: nil, repeats: false)
        
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
                print(lastWord)
                if(lastWord.lowercased() == "read"){ //when red is the first color, bestTranscription sees it as "read"
                    lastWord = "red"
                }
                //this if statement makes sure the word spoken is a color and the player can guess (colorFilter is an array declared at the top)
                if (self.colorFilter.contains(lastWord.lowercased()) && self.playerCanGuess == 1){
                    self.colorCheck(spokenWord: lastWord.lowercased())
                }
            } else if let error = error {
                print(error)
            }
        })
    }

}
